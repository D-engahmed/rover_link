import 'dart:async';

import '../models/rover_telemetry.dart';
import 'rover_command_service.dart';
import 'rover_telemetry_service.dart';

enum FollowRunState { stopped, starting, running, error }

class RoverFollowService {
  static const double stopDistanceCm = 25;
  static const double targetDistanceCm = 60;
  static const double turnDeadbandDeg = 12;

  final RoverTelemetryService telemetryService;
  final RoverCommandService commands;

  StreamSubscription<RoverTelemetry>? _subscription;
  FollowRunState _state = FollowRunState.stopped;
  bool _busy = false;

  RoverFollowService({
    required this.telemetryService,
    required this.commands,
  });

  FollowRunState get state => _state;

  Future<void> start() async {
    if (_state == FollowRunState.running || _state == FollowRunState.starting) return;

    _state = FollowRunState.starting;
    try {
      await _subscription?.cancel();
      _subscription = telemetryService.telemetry.listen(_onTelemetry);

      // Follow-me is phone-side control. Put the STM32 into phone-autonomy
      // mode before movement commands are generated.
      await commands.enterAutonomousMode();
      _state = FollowRunState.running;
    } catch (_) {
      _state = FollowRunState.error;
      await _subscription?.cancel();
      _subscription = null;
      rethrow;
    }
  }

  Future<void> _onTelemetry(RoverTelemetry telemetry) async {
    if (_state != FollowRunState.running || _busy) return;

    final targetDistance = telemetry.targetDistanceCm;
    final targetAngle = telemetry.targetAngleDeg;

    // target_angle_deg must describe the target, not merely the radar servo
    // sweep. Do not move if target tracking data is unavailable.
    if (targetDistance == null || targetAngle == null) return;

    _busy = true;
    try {
      if (targetDistance <= stopDistanceCm) {
        await commands.stop(source: CommandSource.ai);
      } else if (targetAngle < -turnDeadbandDeg) {
        await commands.turnLeft(source: CommandSource.ai);
      } else if (targetAngle > turnDeadbandDeg) {
        await commands.turnRight(source: CommandSource.ai);
      } else if (targetDistance > targetDistanceCm) {
        await commands.moveForward(source: CommandSource.ai);
      } else {
        await commands.stop(source: CommandSource.ai);
      }
    } catch (_) {
      _state = FollowRunState.error;
      try {
        await commands.stop(source: CommandSource.safety);
      } catch (_) {}
    } finally {
      _busy = false;
    }
  }

  Future<void> stop() async {
    _state = FollowRunState.stopped;
    await _subscription?.cancel();
    _subscription = null;
    try {
      await commands.stop(source: CommandSource.system);
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
  }
}

import 'dart:async';

import '../models/rover_telemetry.dart';
import 'rover_command_service.dart';
import 'rover_telemetry_service.dart';

enum AiAction { stop, forward, left, right }
enum AiRunState { stopped, starting, running, error }

class AiDecision {
  final AiAction action;
  final double confidence;
  final double scoreLeft;
  final double scoreForward;
  final double scoreRight;
  final RoverTelemetry telemetry;

  const AiDecision({
    required this.action,
    required this.confidence,
    required this.scoreLeft,
    required this.scoreForward,
    required this.scoreRight,
    required this.telemetry,
  });

  String get label => switch (action) {
        AiAction.stop => 'STOP',
        AiAction.forward => 'FORWARD',
        AiAction.left => 'LEFT',
        AiAction.right => 'RIGHT',
      };
}

/// Local navigation policy executed on the phone.
///
/// The policy is deliberately independent from the UI and backend. It consumes
/// live telemetry and produces bounded movement decisions. This is the
/// deployable navigation baseline while a trained neural model is being
/// collected/evaluated. A trained model can replace decide() without changing
/// the UI or STM32 command contract.
class RoverAiService {
  static const double emergencyStopCm = 18;
  static const double obstacleCm = 45;

  final RoverTelemetryService telemetryService;
  final RoverCommandService commands;

  StreamSubscription<RoverTelemetry>? _subscription;
  final StreamController<AiDecision> _decisions =
      StreamController<AiDecision>.broadcast();

  AiRunState _state = AiRunState.stopped;
  AiDecision? _lastDecision;
  bool _busy = false;

  RoverAiService({
    required this.telemetryService,
    required this.commands,
  });

  AiRunState get state => _state;
  AiDecision? get lastDecision => _lastDecision;
  Stream<AiDecision> get decisions => _decisions.stream;

  Future<void> start() async {
    if (_state == AiRunState.running || _state == AiRunState.starting) return;

    _state = AiRunState.starting;
    try {
      await commands.autopilotMode();
      await _subscription?.cancel();
      _subscription = telemetryService.telemetry.listen(_onTelemetry);
      _state = AiRunState.running;
    } catch (_) {
      _state = AiRunState.error;
      rethrow;
    }
  }

  Future<void> stop() async {
    _state = AiRunState.stopped;
    await _subscription?.cancel();
    _subscription = null;
    try {
      await commands.stop();
    } catch (_) {}
  }

  AiDecision decide(RoverTelemetry t) {
    final front = t.frontDistanceCm ?? 999;
    final left = t.leftDistanceCm ?? front;
    final right = t.rightDistanceCm ?? front;

    if (front <= emergencyStopCm ||
        (left <= emergencyStopCm && right <= emergencyStopCm)) {
      return AiDecision(
        action: AiAction.stop,
        confidence: 1,
        scoreLeft: 0,
        scoreForward: 0,
        scoreRight: 0,
        telemetry: t,
      );
    }

    final l = _clearanceScore(left);
    final f = _clearanceScore(front);
    final r = _clearanceScore(right);

    final targetAngle = t.targetAngleDeg;
    final targetBias = targetAngle == null
        ? 0.0
        : ((targetAngle - 90.0).clamp(-60.0, 60.0) / 60.0).toDouble();

    final leftScore = l - (targetBias > 0 ? targetBias * 0.10 : 0);
    final rightScore = r + (targetBias > 0 ? targetBias * 0.10 : 0);
    final forwardScore = f + (1 - targetBias.abs()) * 0.08;

    AiAction action;
    double best;
    double second;

    if (front < obstacleCm && left < 0.45 && right < 0.45) {
      action = AiAction.stop;
      best = 0;
      second = 0;
    } else if (forwardScore >= leftScore && forwardScore >= rightScore) {
      action = AiAction.forward;
      best = forwardScore;
      second = leftScore > rightScore ? leftScore : rightScore;
    } else if (leftScore >= rightScore) {
      action = AiAction.left;
      best = leftScore;
      second = forwardScore > rightScore ? forwardScore : rightScore;
    } else {
      action = AiAction.right;
      best = rightScore;
      second = forwardScore > leftScore ? forwardScore : leftScore;
    }

    final confidence = ((best - second).abs() + 0.5).clamp(0.5, 0.99).toDouble();

    return AiDecision(
      action: action,
      confidence: confidence,
      scoreLeft: leftScore,
      scoreForward: forwardScore,
      scoreRight: rightScore,
      telemetry: t,
    );
  }

  double _clearanceScore(double distanceCm) {
    if (distanceCm <= emergencyStopCm) return 0;
    return (distanceCm / 150).clamp(0.0, 1.0).toDouble();
  }

  Future<void> _onTelemetry(RoverTelemetry telemetry) async {
    if (_state != AiRunState.running || _busy) return;
    _busy = true;

    try {
      final decision = decide(telemetry);
      _lastDecision = decision;
      _decisions.add(decision);

      switch (decision.action) {
        case AiAction.forward:
          await commands.moveForward();
          break;
        case AiAction.left:
          await commands.turnLeft();
          break;
        case AiAction.right:
          await commands.turnRight();
          break;
        case AiAction.stop:
          await commands.stop();
          break;
      }
    } catch (_) {
      _state = AiRunState.error;
      try {
        await commands.stop();
      } catch (_) {}
    } finally {
      _busy = false;
    }
  }

  Future<void> dispose() async {
    await stop();
    await _decisions.close();
  }
}

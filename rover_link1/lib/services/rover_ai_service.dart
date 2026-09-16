import 'dart:async';

import '../models/command_trace.dart';
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

class RoverAiService {
  static const double emergencyStopCm = 18;
  static const double obstacleCm = 45;

  final RoverTelemetryService telemetryService;
  final RoverCommandService commands;
  StreamSubscription<RoverTelemetry>? _subscription;
  final StreamController<AiDecision> _decisions = StreamController<AiDecision>.broadcast();

  AiRunState _state = AiRunState.stopped;
  AiDecision? _lastDecision;
  bool _busy = false;
  Completer<void>? _inFlight;

  double? _leftClearanceCm;
  double? _frontClearanceCm;
  double? _rightClearanceCm;

  RoverAiService({
    required this.telemetryService,
    required this.commands,
  }) {
    // Manual mode can be selected from the mode screen without going through
    // RoverAiService directly. Register the transition hook so that path is
    // just as safe as pressing the AI STOP button.
    commands.beforeManualMode = stop;
  }

  AiRunState get state => _state;
  AiDecision? get lastDecision => _lastDecision;
  Stream<AiDecision> get decisions => _decisions.stream;

  Future<void> start() async {
    if (_state == AiRunState.running || _state == AiRunState.starting) return;

    _state = AiRunState.starting;
    _resetSweepMemory();

    try {
      // Subscribe before switching the STM32 into phone-autonomy mode so the
      // first telemetry packets are not missed.
      await _subscription?.cancel();
      _subscription = telemetryService.telemetry.listen(_onTelemetry);

      // Mode transition is serialized as STOP -> AUTONOMOUS MODE.
      await commands.enterAutonomousMode();

      _state = AiRunState.running;
    } catch (_) {
      _state = AiRunState.error;
      await _subscription?.cancel();
      _subscription = null;
      rethrow;
    }
  }

  Future<void> stop() async {
    final wasRunning = _state != AiRunState.stopped;
    _state = AiRunState.stopped;

    await _subscription?.cancel();
    _subscription = null;

    // Do not switch to another mode until an already-running AI command has
    // completed. Otherwise its late W/A/D/P packet can arrive after M.
    final inFlight = _inFlight;
    if (inFlight != null && !inFlight.isCompleted) {
      await inFlight.future;
    }

    _resetSweepMemory();

    if (wasRunning) {
      try {
        await commands.stop(source: CommandSource.system);
      } catch (_) {}
    }
  }

  AiDecision decide(RoverTelemetry t) {
    _updateSweepMemory(t);

    final front = _frontClearanceCm ?? t.frontDistanceCm ?? 999;
    final left = _leftClearanceCm ?? front;
    final right = _rightClearanceCm ?? front;

    if (front <= emergencyStopCm || (left <= emergencyStopCm && right <= emergencyStopCm)) {
      return AiDecision(action: AiAction.stop, confidence: 1, scoreLeft: 0, scoreForward: 0, scoreRight: 0, telemetry: t);
    }

    final l = _clearanceScore(left);
    final f = _clearanceScore(front);
    final r = _clearanceScore(right);

    double leftScore = l;
    double rightScore = r;
    double forwardScore = f;

    if (front < obstacleCm) forwardScore = 0;
    if (left < obstacleCm) leftScore *= 0.35;
    if (right < obstacleCm) rightScore *= 0.35;

    AiAction action;
    double best;
    double second;

    if (forwardScore >= leftScore && forwardScore >= rightScore) {
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

    if (best <= 0.05) {
      action = AiAction.stop;
      best = 0;
      second = 0;
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

  double _clearanceScore(double distanceCm) => distanceCm <= emergencyStopCm
      ? 0
      : (distanceCm / 150).clamp(0.0, 1.0).toDouble();

  void _resetSweepMemory() {
    _leftClearanceCm = null;
    _frontClearanceCm = null;
    _rightClearanceCm = null;
  }

  void _updateSweepMemory(RoverTelemetry t) {
    final distance = t.ultrasonicDistanceCm ?? t.frontDistanceCm;
    final angle = t.radarAngleDeg;

    if (distance == null || angle == null) return;

    if (angle >= 70 && angle <= 110) {
      _frontClearanceCm = _minDistance(_frontClearanceCm, distance);
    } else if (angle < 70) {
      _leftClearanceCm = _minDistance(_leftClearanceCm, distance);
    } else {
      _rightClearanceCm = _minDistance(_rightClearanceCm, distance);
    }
  }

  double _minDistance(double? current, double incoming) {
    if (current == null) return incoming;
    return incoming < current ? incoming : current;
  }

  Future<void> _onTelemetry(RoverTelemetry telemetry) async {
    if (_state != AiRunState.running || _busy) return;

    _busy = true;
    final inFlight = Completer<void>();
    _inFlight = inFlight;

    try {
      final decision = decide(telemetry);
      _lastDecision = decision;
      _decisions.add(decision);

      const source = CommandSource.ai;

      switch (decision.action) {
        case AiAction.forward:
          await commands.moveForward(source: source);
          break;
        case AiAction.left:
          await commands.turnLeft(source: source);
          break;
        case AiAction.right:
          await commands.turnRight(source: source);
          break;
        case AiAction.stop:
          await commands.stop(source: source);
          break;
      }
    } catch (_) {
      _state = AiRunState.error;
      try {
        await commands.stop(source: CommandSource.safety);
      } catch (_) {}
    } finally {
      _busy = false;
      if (!inFlight.isCompleted) inFlight.complete();
      if (identical(_inFlight, inFlight)) _inFlight = null;
    }
  }

  Future<void> dispose() async {
    await stop();
    await _decisions.close();
  }
}

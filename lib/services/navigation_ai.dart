import 'dart:math' as math;

enum NavAction { forward, turnLeft, turnRight, stop, avoidLeft, avoidRight, search }

class NavigationDecision {
  const NavigationDecision({
    required this.action,
    required this.label,
    required this.targetSpeedPct,
    required this.confidencePct,
  });

  final NavAction action;
  final String label;
  final double targetSpeedPct;
  final double confidencePct;
}

/// Rule-based follow-me controller — NOT a trained ML model. It smooths
/// noisy distance/bearing readings and turns them into a steering decision
/// plus a confidence score, the same way the UI spec's "AI" panels
/// (localization / prediction / navigation / confidence) describe it.
///
/// If you specifically want a trained model later (e.g. an RSSI→distance
/// regression calibrated from real readings, or a learned Kalman-filter
/// tune), this class is the right place to swap the smoothing/decision
/// functions for model inference — the public API (`update`, `decide`)
/// wouldn't need to change.
class NavigationAI {
  NavigationAI({
    this.followDistanceM = 1.5,
    this.obstacleThresholdCm = 30,
    this.bearingDeadzoneDeg = 8,
    this.smoothing = 0.35,
  });

  final double followDistanceM;
  final double obstacleThresholdCm;
  final double bearingDeadzoneDeg;

  /// Exponential-moving-average factor (0..1). Higher = trusts new readings
  /// more; lower = smoother but laggier. 0.35 is a reasonable starting
  /// point for ~5-10 Hz sensor updates over a serial link.
  final double smoothing;

  double? _smoothedDistanceM;
  double? _smoothedBearingDeg;
  final List<double> _recentJitter = [];

  /// Feed a raw reading in; returns the smoothed (distance, bearing).
  (double, double) update({required double rawDistanceM, required double rawBearingDeg}) {
    _smoothedDistanceM = _smoothedDistanceM == null
        ? rawDistanceM
        : _smoothedDistanceM! + smoothing * (rawDistanceM - _smoothedDistanceM!);
    _smoothedBearingDeg = _smoothedBearingDeg == null
        ? rawBearingDeg
        : _smoothedBearingDeg! + smoothing * (rawBearingDeg - _smoothedBearingDeg!);

    // Track short-term jitter as a proxy for signal quality -> confidence.
    _recentJitter.add((rawDistanceM - _smoothedDistanceM!).abs());
    if (_recentJitter.length > 12) _recentJitter.removeAt(0);

    return (_smoothedDistanceM!, _smoothedBearingDeg!);
  }

  double get _confidencePct {
    if (_recentJitter.isEmpty) return 50;
    final avgJitter = _recentJitter.reduce((a, b) => a + b) / _recentJitter.length;
    // More jitter (m) -> lower confidence. Tuned so ~0m jitter -> ~98%,
    // ~1m steady jitter -> ~40%.
    final conf = 98 - avgJitter * 58;
    return conf.clamp(15, 98);
  }

  /// Core decision: given the latest smoothed target reading and the
  /// nearest obstacle distance, decide what the rover should do next.
  /// Obstacle avoidance always overrides following.
  NavigationDecision decide({required double obstacleCm, bool targetVisible = true}) {
    if (obstacleCm <= obstacleThresholdCm) {
      final avoidLeft = obstacleCm.round().isEven; // placeholder side choice
      return NavigationDecision(
        action: avoidLeft ? NavAction.avoidLeft : NavAction.avoidRight,
        label: avoidLeft ? 'AVOID LEFT' : 'AVOID RIGHT',
        targetSpeedPct: 15,
        confidencePct: _confidencePct,
      );
    }

    if (!targetVisible || _smoothedDistanceM == null) {
      return NavigationDecision(
        action: NavAction.search,
        label: 'SEARCHING FOR TARGET',
        targetSpeedPct: 0,
        confidencePct: (_confidencePct * 0.4).clamp(10, 100),
      );
    }

    final distance = _smoothedDistanceM!;
    final bearing = _smoothedBearingDeg!;

    if (distance <= followDistanceM) {
      return NavigationDecision(
        action: NavAction.stop,
        label: 'HOLDING POSITION',
        targetSpeedPct: 0,
        confidencePct: _confidencePct,
      );
    }

    if (bearing.abs() <= bearingDeadzoneDeg) {
      return NavigationDecision(
        action: NavAction.forward,
        label: 'FORWARD',
        targetSpeedPct: _speedForDistance(distance),
        confidencePct: _confidencePct,
      );
    }

    final turningRight = bearing > 0;
    return NavigationDecision(
      action: turningRight ? NavAction.turnRight : NavAction.turnLeft,
      label: 'TURN ${turningRight ? 'RIGHT' : 'LEFT'} ${bearing.abs().toStringAsFixed(0)}° → FORWARD',
      targetSpeedPct: _speedForDistance(distance) * 0.7,
      confidencePct: _confidencePct,
    );
  }

  double _speedForDistance(double distanceM) {
    // Slow down as the rover closes in on the follow distance so it doesn't
    // overshoot and bump the target.
    final margin = (distanceM - followDistanceM).clamp(0, 4);
    return (30 + margin * 17.5).clamp(0, 100);
  }
}

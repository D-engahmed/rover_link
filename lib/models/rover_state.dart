import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../services/bluetooth_service.dart';
import '../services/navigation_ai.dart';
import '../services/rover_link_protocol.dart';

/// The four control modes described in the UI spec.
enum RoverMode { manual, assisted, followMe, autonomous }

extension RoverModeLabel on RoverMode {
  String get label {
    switch (this) {
      case RoverMode.manual:
        return 'MANUAL';
      case RoverMode.assisted:
        return 'ASSISTED';
      case RoverMode.followMe:
        return 'FOLLOW ME';
      case RoverMode.autonomous:
        return 'AUTONOMOUS';
    }
  }

  String get wireValue {
    switch (this) {
      case RoverMode.manual:
        return 'manual';
      case RoverMode.assisted:
        return 'assisted';
      case RoverMode.followMe:
        return 'follow_me';
      case RoverMode.autonomous:
        return 'autonomous';
    }
  }
}

/// High-level mission/navigation status. The UI only ever *visualizes*
/// this — the STM32 + navigation engine are the source of truth for what
/// actually happens; [NavigationAI] just proposes it from phone-side data.
enum MissionStatus { idle, approaching, navigating, avoiding, searching, emergency }

extension MissionStatusLabel on MissionStatus {
  String get label {
    switch (this) {
      case MissionStatus.idle:
        return 'IDLE';
      case MissionStatus.approaching:
        return 'APPROACHING';
      case MissionStatus.navigating:
        return 'NAVIGATING';
      case MissionStatus.avoiding:
        return 'AVOIDING OBSTACLE';
      case MissionStatus.searching:
        return 'SEARCHING FOR TARGET';
      case MissionStatus.emergency:
        return 'EMERGENCY STOP';
    }
  }
}

/// A single obstacle blip on the radar, in polar form relative to the rover.
class RadarObstacle {
  const RadarObstacle({required this.angleDeg, required this.distanceM});
  final double angleDeg;
  final double distanceM;
}

/// One shared state object for the whole app.
///
/// Two data sources feed it:
/// - [RoverConnection]: raw telemetry off the HC-05 serial link (real
///   hardware, when connected).
/// - [simulateTick]: synthetic jitter, used only when there's no live
///   connection, so the UI is never dead on screen.
///
/// [NavigationAI] turns raw target readings into a smoothed, confident
/// follow-me decision — it runs on live data, not on the simulator.
class RoverState extends ChangeNotifier {
  RoverState() {
    _connection.status.listen(_onLinkStatus);
    _connection.telemetry.listen(_onPacket);
  }

  final RoverConnection _connection = RoverConnection();
  final NavigationAI _ai = NavigationAI();

  RoverConnection get connection => _connection;
  bool get isLive => _connection.currentStatus == RoverLinkStatus.connected;

  RoverMode mode = RoverMode.followMe;
  MissionStatus missionStatus = MissionStatus.approaching;
  bool connected = false;
  bool emergencyStop = false;

  // Target / follow-me telemetry
  String targetName = 'YOU';
  double targetDistanceM = 4.72;
  double targetBearingDeg = 27;
  double confidencePct = 91;

  // AI navigation
  String aiDecision = 'TURN RIGHT 18° → FORWARD';
  double positionErrorM = 0.42;
  double distanceErrorM = 0.31;

  // Local sensing / telemetry (as reported by the STM32 over the serial link)
  double ultrasonicCm = 84;
  double servoAngleDeg = 74;
  double motorSpeedPct = 48;
  int rssiDbm = -57;
  int latencyMs = 42;
  bool safetyClear = true;

  // Manual drive
  double driveSpeedPct = 62;

  final List<RadarObstacle> obstacles = const [
    RadarObstacle(angleDeg: 140, distanceM: 2.1),
    RadarObstacle(angleDeg: 320, distanceM: 3.4),
  ];

  // ---- Mode / commands -----------------------------------------------

  void setMode(RoverMode newMode) {
    mode = newMode;
    _connection.sendCommand('set_mode', {'mode': newMode.wireValue});
    notifyListeners();
  }

  void sendDriveCommand(String direction) {
    _connection.sendCommand('drive', {'dir': direction, 'speed': driveSpeedPct});
  }

  void triggerEmergencyStop() {
    emergencyStop = true;
    missionStatus = MissionStatus.emergency;
    motorSpeedPct = 0;
    _connection.sendCommand('estop');
    notifyListeners();
  }

  void clearEmergencyStop() {
    emergencyStop = false;
    missionStatus = MissionStatus.approaching;
    _connection.sendCommand('resume');
    notifyListeners();
  }

  // ---- Live link --------------------------------------------------------

  void _onLinkStatus(RoverLinkStatus status) {
    connected = status == RoverLinkStatus.connected;
    notifyListeners();
  }

  void _onPacket(RoverPacket packet) {
    if (packet.type != 'telemetry') return;
    final f = packet.fields;
    final rawDistance = (f['tgt_d'] as num?)?.toDouble();
    final rawBearing = (f['tgt_b'] as num?)?.toDouble();
    ultrasonicCm = (f['us_cm'] as num?)?.toDouble() ?? ultrasonicCm;
    servoAngleDeg = (f['servo'] as num?)?.toDouble() ?? servoAngleDeg;

    final targetVisible = rawDistance != null && rawBearing != null;
    if (targetVisible) {
      final (smoothedDist, smoothedBearing) =
          _ai.update(rawDistanceM: rawDistance, rawBearingDeg: rawBearing);
      targetDistanceM = smoothedDist;
      targetBearingDeg = smoothedBearing;
    }

    final decision = _ai.decide(obstacleCm: ultrasonicCm, targetVisible: targetVisible);
    confidencePct = decision.confidencePct;
    aiDecision = decision.label;
    safetyClear = ultrasonicCm > _ai.obstacleThresholdCm;
    missionStatus = _statusForAction(decision.action);

    if (mode == RoverMode.followMe || mode == RoverMode.autonomous) {
      motorSpeedPct = decision.targetSpeedPct;
    } else {
      motorSpeedPct = (f['motor'] as num?)?.toDouble() ?? motorSpeedPct;
    }

    notifyListeners();
  }

  MissionStatus _statusForAction(NavAction action) {
    switch (action) {
      case NavAction.forward:
      case NavAction.turnLeft:
      case NavAction.turnRight:
        return MissionStatus.approaching;
      case NavAction.stop:
        return MissionStatus.navigating;
      case NavAction.avoidLeft:
      case NavAction.avoidRight:
        return MissionStatus.avoiding;
      case NavAction.search:
        return MissionStatus.searching;
    }
  }

  // ---- Demo fallback ------------------------------------------------------

  /// Cheap jitter so the dashboard isn't static when nothing is connected.
  /// Skipped automatically once a live link is up — see [isLive].
  void simulateTick() {
    if (isLive) return;
    final rand = math.Random();
    targetDistanceM = (targetDistanceM + (rand.nextDouble() - 0.5) * 0.15).clamp(0.3, 8.0);
    targetBearingDeg = (targetBearingDeg + (rand.nextDouble() - 0.5) * 4).clamp(-90.0, 90.0);
    confidencePct = (confidencePct + (rand.nextDouble() - 0.5) * 2).clamp(40.0, 99.0);
    ultrasonicCm = (ultrasonicCm + (rand.nextDouble() - 0.5) * 6).clamp(5.0, 250.0);
    rssiDbm = (-40 - rand.nextInt(35));
    notifyListeners();
  }

  @override
  void dispose() {
    _connection.dispose();
    super.dispose();
  }
}

enum RoverConnectionState { disconnected, scanning, connecting, connected, ready, reconnecting }
enum RoverMode { manual, autonomous, emergencyStop }
enum RoverMotion { stopped, forward, backward, left, right }

class RoverState {
  final RoverConnectionState connection;
  final RoverMode mode;
  final RoverMotion motion;
  final int? rssi;
  final int batteryPercent;
  final int? frontDistanceCm;
  final bool targetDetected;
  final String? targetType;
  final double targetConfidence;

  const RoverState({
    this.connection = RoverConnectionState.disconnected,
    this.mode = RoverMode.manual,
    this.motion = RoverMotion.stopped,
    this.rssi,
    this.batteryPercent = 0,
    this.frontDistanceCm,
    this.targetDetected = false,
    this.targetType,
    this.targetConfidence = 0,
  });

  RoverState copyWith({
    RoverConnectionState? connection,
    RoverMode? mode,
    RoverMotion? motion,
    int? rssi,
    int? batteryPercent,
    int? frontDistanceCm,
    bool? targetDetected,
    String? targetType,
    double? targetConfidence,
  }) => RoverState(
    connection: connection ?? this.connection,
    mode: mode ?? this.mode,
    motion: motion ?? this.motion,
    rssi: rssi ?? this.rssi,
    batteryPercent: batteryPercent ?? this.batteryPercent,
    frontDistanceCm: frontDistanceCm ?? this.frontDistanceCm,
    targetDetected: targetDetected ?? this.targetDetected,
    targetType: targetType ?? this.targetType,
    targetConfidence: targetConfidence ?? this.targetConfidence,
  );
}

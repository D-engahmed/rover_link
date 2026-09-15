class RoverTelemetry {
  final int timestampMs;
  final double? frontDistanceCm;
  final double? leftDistanceCm;
  final double? rightDistanceCm;
  final double? targetDistanceCm;
  final double? targetAngleDeg;
  final double? speedCmS;
  final int? rssiDbm;
  final String? mode;

  const RoverTelemetry({
    required this.timestampMs,
    this.frontDistanceCm,
    this.leftDistanceCm,
    this.rightDistanceCm,
    this.targetDistanceCm,
    this.targetAngleDeg,
    this.speedCmS,
    this.rssiDbm,
    this.mode,
  });

  static double? _number(dynamic value) => value is num ? value.toDouble() : null;

  factory RoverTelemetry.fromJson(Map<String, dynamic> json) => RoverTelemetry(
        timestampMs: (json['timestamp_ms'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
        frontDistanceCm: _number(json['front_distance_cm']),
        leftDistanceCm: _number(json['left_distance_cm']),
        rightDistanceCm: _number(json['right_distance_cm']),
        targetDistanceCm: _number(json['target_distance_cm']),
        targetAngleDeg: _number(json['target_angle_deg']),
        speedCmS: _number(json['speed_cm_s']),
        rssiDbm: (json['rssi_dbm'] as num?)?.toInt(),
        mode: json['mode']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'timestamp_ms': timestampMs,
        'front_distance_cm': frontDistanceCm,
        'left_distance_cm': leftDistanceCm,
        'right_distance_cm': rightDistanceCm,
        'target_distance_cm': targetDistanceCm,
        'target_angle_deg': targetAngleDeg,
        'speed_cm_s': speedCmS,
        'rssi_dbm': rssiDbm,
        'mode': mode,
      };
}

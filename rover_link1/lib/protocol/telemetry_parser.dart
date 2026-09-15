import '../rover/rover_state.dart';

/// Transitional parser for newline-delimited telemetry emitted by the rover.
/// Expected format: key=value;key=value;...
class TelemetryParser {
  RoverState parse(String line, RoverState current) {
    final values = <String, String>{};
    for (final item in line.trim().split(';')) {
      final parts = item.split('=');
      if (parts.length == 2) values[parts[0].trim()] = parts[1].trim();
    }

    int? intValue(String key) => int.tryParse(values[key] ?? '');
    double doubleValue(String key) => double.tryParse(values[key] ?? '') ?? 0;

    return current.copyWith(
      batteryPercent: intValue('battery') ?? current.batteryPercent,
      frontDistanceCm: intValue('front') ?? current.frontDistanceCm,
      targetDetected: values['target'] == '1' ? true : values['target'] == '0' ? false : current.targetDetected,
      targetType: values['target_type'] ?? current.targetType,
      targetConfidence: doubleValue('confidence'),
    );
  }
}

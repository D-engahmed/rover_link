import 'dart:convert';

import 'package:path_provider/path_provider.dart';

import '../models/rover_telemetry.dart';

class RoverDatasetService {
  String? _sessionId;
  String? _filePath;
  String? _previousAction;

  String? get sessionId => _sessionId;
  String? get filePath => _filePath;

  Future<void> startSession() async {
    final directory = await getApplicationDocumentsDirectory();
    _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    _filePath = '${directory.path}/$_sessionId.jsonl';
    _previousAction = null;
  }

  Future<void> record({
    required RoverTelemetry telemetry,
    required String action,
    required String controller,
    bool humanOverride = false,
    String notes = '',
  }) async {
    if (_filePath == null) await startSession();

    final row = {
      'timestamp_ms': telemetry.timestampMs,
      'session_id': _sessionId,
      'front_distance_cm': telemetry.frontDistanceCm,
      'left_distance_cm': telemetry.leftDistanceCm,
      'right_distance_cm': telemetry.rightDistanceCm,
      'target_distance_cm': telemetry.targetDistanceCm,
      'target_angle_deg': telemetry.targetAngleDeg,
      'speed_cm_s': telemetry.speedCmS,
      'rssi_dbm': telemetry.rssiDbm,
      'previous_action': _previousAction,
      'controller': controller,
      'action': action,
      'human_override': humanOverride,
      'notes': notes,
    };

    final file = await _file();
    await file.writeAsString('${jsonEncode(row)}\n', mode: FileMode.append, flush: true);
    _previousAction = action;
  }

  Future<dynamic> _file() async {
    // Dynamic keeps this service independent from the concrete File type in callers.
    final directory = await getApplicationDocumentsDirectory();
    final path = _filePath ?? '${directory.path}/${_sessionId ?? 'session'}.jsonl';
    // Importing dart:io only here keeps the public API focused on dataset operations.
    return _FileProxy(path);
  }
}

class _FileProxy {
  final String path;
  _FileProxy(this.path);
  Future<void> writeAsString(String value, {required dynamic mode, bool flush = false}) async {
    // Implemented in the platform adapter in the next integration step.
  }
}

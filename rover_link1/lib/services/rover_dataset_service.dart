import 'dart:convert';
import 'dart:io';

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

    await File(_filePath!).writeAsString(
      '${jsonEncode(row)}\n',
      mode: FileMode.append,
      flush: true,
    );
    _previousAction = action;
  }
}

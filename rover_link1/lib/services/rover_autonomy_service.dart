import 'dart:async';

import '../models/rover_telemetry.dart';
import 'baseline_navigation_service.dart';
import 'rover_command_service.dart';
import 'rover_dataset_service.dart';
import 'rover_telemetry_service.dart';

class RoverAutonomyService {
  final RoverTelemetryService telemetryService;
  final BaselineNavigationService baseline;
  final RoverDatasetService dataset;

  StreamSubscription<RoverTelemetry>? _subscription;
  bool _enabled = false;
  bool _busy = false;

  RoverAutonomyService({
    required RoverTelemetryService telemetryService,
    required RoverCommandService commands,
    required RoverDatasetService dataset,
  })  : telemetryService = telemetryService,
        baseline = BaselineNavigationService(commands),
        dataset = dataset;

  bool get enabled => _enabled;

  Future<void> startBaseline() async {
    if (_enabled) return;
    await dataset.startSession();
    telemetryService.start();
    _enabled = true;
    _subscription = telemetryService.telemetry.listen(_onTelemetry);
  }

  Future<void> _onTelemetry(RoverTelemetry state) async {
    if (!_enabled || _busy) return;
    _busy = true;
    try {
      final action = await baseline.step(state);
      if (action != null) {
        await dataset.record(
          telemetry: state,
          action: action,
          controller: 'baseline_v1',
        );
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> stop() async {
    _enabled = false;
    await _subscription?.cancel();
    _subscription = null;
  }
}

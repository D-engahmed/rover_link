import 'dart:async';
import 'dart:convert';

import '../models/rover_telemetry.dart';
import 'bluetooth_service.dart';

class RoverTelemetryService {
  final BluetoothService bluetoothService;
  StreamSubscription<String>? _subscription;
  final _controller = StreamController<RoverTelemetry>.broadcast();

  RoverTelemetryService(this.bluetoothService);

  Stream<RoverTelemetry> get telemetry => _controller.stream;

  void start() {
    _subscription?.cancel();
    _subscription = bluetoothService.receiveMessages().listen((line) {
      try {
        final decoded = jsonDecode(line.trim());
        if (decoded is Map<String, dynamic>) {
          _controller.add(RoverTelemetry.fromJson(decoded));
        }
      } catch (_) {
        // Ignore non-telemetry lines; the command channel can still carry logs.
      }
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}

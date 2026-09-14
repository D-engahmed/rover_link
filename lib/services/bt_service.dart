import 'dart:async';
import 'dart:math';

enum BtLinkState { disconnected, scanning, connecting, connected }

class BtDevice {
  final String name;
  final String address;
  final bool connectable;
  const BtDevice({
    required this.name,
    required this.address,
    this.connectable = true,
  });
}

abstract class BtService {
  Stream<BtLinkState> get linkState;
  Stream<BtDevice> get deviceDiscovered;
  Stream<String> get linesReceived;
  Stream<String> get connectionError;
  Future<void> startScan();
  Future<void> stopScan();
  Future<void> connect(BtDevice device);
  Future<void> disconnect();
  Future<void> writeLine(String data);
  void dispose();
}

/// Simulated transport. It is only reachable when ROVER_DEMO=true.
class DemoBtService implements BtService {
  final _linkStateCtrl = StreamController<BtLinkState>.broadcast();
  final _deviceCtrl = StreamController<BtDevice>.broadcast();
  final _lineCtrl = StreamController<String>.broadcast();
  final _errorCtrl = StreamController<String>.broadcast();
  Timer? _scanTimer;
  Timer? _telemetryTimer;
  final _rng = Random(42);
  double _obstacleCm = 160;
  bool _disposed = false;

  static const _nearby = [
    BtDevice(name: 'HC-05 · Rover', address: '00:21:13:01:23:45'),
    BtDevice(name: 'Galaxy Buds2', address: 'A4:11:9F:3C:8B:02', connectable: false),
    BtDevice(name: 'ESP32-CAM', address: 'AA:BB:CC:11:22:33', connectable: false),
  ];

  @override Stream<BtLinkState> get linkState => _linkStateCtrl.stream;
  @override Stream<BtDevice> get deviceDiscovered => _deviceCtrl.stream;
  @override Stream<String> get linesReceived => _lineCtrl.stream;
  @override Stream<String> get connectionError => _errorCtrl.stream;

  @override
  Future<void> startScan() async {
    if (_disposed) return;
    _linkStateCtrl.add(BtLinkState.scanning);
    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(milliseconds: 300), () {
      if (_disposed) return;
      for (final d in _nearby) {
        _deviceCtrl.add(d);
      }
    });
  }

  @override
  Future<void> stopScan() async {
    _scanTimer?.cancel();
    if (!_disposed) _linkStateCtrl.add(BtLinkState.disconnected);
  }

  @override
  Future<void> connect(BtDevice device) async {
    if (_disposed || !device.connectable) return;
    _linkStateCtrl.add(BtLinkState.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (_disposed) return;
    _obstacleCm = 160;
    _linkStateCtrl.add(BtLinkState.connected);
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(
      const Duration(milliseconds: 1100),
      (_) => _emitTelemetry(),
    );
  }

  void _emitTelemetry() {
    if (_disposed) return;
    _obstacleCm = (_obstacleCm + (_rng.nextDouble() - 0.5) * 30).clamp(12, 220);
    _lineCtrl.add('+US:${_obstacleCm.toStringAsFixed(0)}cm');
    _lineCtrl.add('+RSSI:${-58 - _rng.nextInt(14)}');
    final dist = 1.2 + _rng.nextDouble() * 2.6;
    _lineCtrl.add('+DIST:${dist.toStringAsFixed(2)}m');
  }

  @override
  Future<void> disconnect() async {
    _telemetryTimer?.cancel();
    if (!_disposed) _linkStateCtrl.add(BtLinkState.disconnected);
  }

  @override
  Future<void> writeLine(String data) async {
    if (_disposed) return;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    if (_disposed) return;
    _lineCtrl.add(data.startsWith('AT') ? 'OK' : 'ACK:$data');
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _scanTimer?.cancel();
    _telemetryTimer?.cancel();
    _linkStateCtrl.close();
    _deviceCtrl.close();
    _lineCtrl.close();
    _errorCtrl.close();
  }
}

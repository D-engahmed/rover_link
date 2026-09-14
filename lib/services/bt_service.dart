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

/// Everything RoverState needs from a Bluetooth transport. Swap
/// DemoBtService for RealBtService (real_bt_service.dart) once you're ready
/// to test on a physical Android device with the rover powered on — nothing
/// else in the app needs to change.
abstract class BtService {
  Stream<BtLinkState> get linkState;
  Stream<BtDevice> get deviceDiscovered;
  Stream<String> get linesReceived; // one decoded ASCII line per event
  Stream<String> get connectionError;

  Future<void> startScan();
  Future<void> stopScan();
  Future<void> connect(BtDevice device);
  Future<void> disconnect();
  Future<void> writeLine(String data);
  void dispose();
}

/// Simulated transport so the whole app builds, runs, and can be demoed on
/// any device or emulator with zero hardware attached. This produces the
/// same "DEMO DATA" placeholder telemetry the HTML prototype had — just
/// driven from a Dart Timer instead of setInterval().
///
/// NOTE: the '+US:' (ultrasonic, cm) and '+DIST:' (RSSI-derived target
/// distance, m) tags below are PLACEHOLDERS matching what the HTML mock
/// invented. They are not your real firmware's wire format. RoverState
/// parses these same tags from RealBtService too — update the parsing in
/// RoverState._onLine (and these tags here) once you confirm your actual
/// protocol.
class DemoBtService implements BtService {
  final _linkStateCtrl = StreamController<BtLinkState>.broadcast();
  final _deviceCtrl = StreamController<BtDevice>.broadcast();
  final _lineCtrl = StreamController<String>.broadcast();
  final _errorCtrl = StreamController<String>.broadcast();
  Timer? _scanTimer;
  Timer? _telemetryTimer;
  final _rng = Random();
  double _obstacleCm = 160;

  static const _nearby = [
    BtDevice(name: 'HC-05 · Rover', address: '00:21:13:01:23:45'),
    BtDevice(name: 'Galaxy Buds2', address: 'A4:11:9F:3C:8B:02', connectable: false),
    BtDevice(name: 'ESP32-CAM', address: 'AA:BB:CC:11:22:33', connectable: false),
  ];

  @override
  Stream<BtLinkState> get linkState => _linkStateCtrl.stream;
  @override
  Stream<BtDevice> get deviceDiscovered => _deviceCtrl.stream;
  @override
  Stream<String> get linesReceived => _lineCtrl.stream;
  @override
  Stream<String> get connectionError => _errorCtrl.stream;

  @override
  Future<void> startScan() async {
    _linkStateCtrl.add(BtLinkState.scanning);
    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(milliseconds: 1200), () {
      for (final d in _nearby) {
        _deviceCtrl.add(d);
      }
    });
  }

  @override
  Future<void> stopScan() async {
    _scanTimer?.cancel();
  }

  @override
  Future<void> connect(BtDevice device) async {
    _linkStateCtrl.add(BtLinkState.connecting);
    await Future.delayed(const Duration(milliseconds: 900));
    if (_rng.nextDouble() < 0.2) {
      _errorCtrl.add(
          "${device.name} didn't respond. It may be out of range or already linked elsewhere.");
      _linkStateCtrl.add(BtLinkState.disconnected);
      return;
    }
    _obstacleCm = 160;
    _linkStateCtrl.add(BtLinkState.connected);
    _telemetryTimer?.cancel();
    _telemetryTimer =
        Timer.periodic(const Duration(milliseconds: 1100), (_) => _emitTelemetry());
  }

  void _emitTelemetry() {
    _obstacleCm = (_obstacleCm + (_rng.nextDouble() - 0.5) * 30).clamp(12, 220);
    _lineCtrl.add('+US:${_obstacleCm.toStringAsFixed(0)}cm');
    if (_rng.nextDouble() > 0.5) {
      final rssi = -58 - _rng.nextInt(14);
      _lineCtrl.add('+RSSI:$rssi');
    }
    if (_rng.nextDouble() > 0.5) {
      final dist = 1.2 + _rng.nextDouble() * 2.6;
      _lineCtrl.add('+DIST:${dist.toStringAsFixed(2)}m');
    }
  }

  @override
  Future<void> disconnect() async {
    _telemetryTimer?.cancel();
    _linkStateCtrl.add(BtLinkState.disconnected);
  }

  @override
  Future<void> writeLine(String data) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _lineCtrl.add(data.startsWith('AT') ? 'OK' : 'ACK:$data');
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _telemetryTimer?.cancel();
    _linkStateCtrl.close();
    _deviceCtrl.close();
    _lineCtrl.close();
    _errorCtrl.close();
  }
}

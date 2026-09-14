import 'dart:async';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart' as bc;
import 'bt_service.dart';
import '../constants.dart';

/// Wraps the `bluetooth_classic` package (Android-only, RFCOMM/SPP) — the
/// actual transport your STM32 talks over via HC-05.
///
/// NOT VERIFIED AGAINST REAL HARDWARE OR EVEN COMPILED. Written from the
/// package's published docs/examples (checked live via search), but this
/// sandbox has no Flutter SDK and no network access to pub.dev, so none of
/// this has been run. Test on a real Android phone with the rover powered
/// on — emulators don't have real Bluetooth radios — and send back whatever
/// `flutter analyze` / `flutter run` gives you; the method names and Device
/// model fields below are the most likely place for a version mismatch.
///
/// Also, deliberately: this only targets Android. iOS cannot talk to HC-05
/// at all without Apple's MFi accessory certification, which HC-05 doesn't
/// have. If iOS ever becomes a requirement, that's a hardware decision (a
/// BLE module instead of HC-05), not something fixable in this file.
class RealBtService implements BtService {
  final _plugin = BluetoothClassic();
  final _linkStateCtrl = StreamController<BtLinkState>.broadcast();
  final _deviceCtrl = StreamController<BtDevice>.broadcast();
  final _lineCtrl = StreamController<String>.broadcast();
  final _errorCtrl = StreamController<String>.broadcast();
  String _rxBuffer = '';
  bool _permissionsReady = false;

  RealBtService() {
    _plugin.onDeviceDiscovered().listen((bc.Device d) {
      _deviceCtrl.add(BtDevice(name: d.name ?? d.address, address: d.address));
    });

    _plugin.onDeviceStatusChanged().listen((int status) {
      // bc.Device.connected / bc.Device.disconnected are the documented
      // status ints for this package — confirm they match the version
      // that actually resolves when you run `flutter pub get`.
      if (status == bc.Device.connected) {
        _linkStateCtrl.add(BtLinkState.connected);
      } else if (status == bc.Device.disconnected) {
        _linkStateCtrl.add(BtLinkState.disconnected);
      }
    });

    _plugin.onDeviceDataReceived().listen((List<int> bytes) {
      _rxBuffer += String.fromCharCodes(bytes);
      while (_rxBuffer.contains('\n')) {
        final idx = _rxBuffer.indexOf('\n');
        final line = _rxBuffer.substring(0, idx).trim();
        _rxBuffer = _rxBuffer.substring(idx + 1);
        if (line.isNotEmpty) _lineCtrl.add(line);
      }
    });
  }

  @override
  Stream<BtLinkState> get linkState => _linkStateCtrl.stream;
  @override
  Stream<BtDevice> get deviceDiscovered => _deviceCtrl.stream;
  @override
  Stream<String> get linesReceived => _lineCtrl.stream;
  @override
  Stream<String> get connectionError => _errorCtrl.stream;

  Future<void> _ensurePermissions() async {
    if (_permissionsReady) return;
    await _plugin.initPermissions();
    _permissionsReady = true;
  }

  @override
  Future<void> startScan() async {
    await _ensurePermissions();
    _linkStateCtrl.add(BtLinkState.scanning);
    try {
      final paired = await _plugin.getPairedDevices();
      for (final d in paired) {
        _deviceCtrl.add(BtDevice(name: d.name ?? d.address, address: d.address));
      }
      await _plugin.startScan();
    } catch (e) {
      _errorCtrl.add('Scan failed: $e');
    }
  }

  @override
  Future<void> stopScan() async {
    try {
      await _plugin.stopScan();
    } catch (_) {
      // Non-fatal — the scan may already have stopped.
    }
  }

  @override
  Future<void> connect(BtDevice device) async {
    _linkStateCtrl.add(BtLinkState.connecting);
    try {
      await _plugin.connect(device.address, sppUuid);
      _linkStateCtrl.add(BtLinkState.connected);
    } catch (e) {
      _errorCtrl.add("Could not connect to ${device.name}: $e");
      _linkStateCtrl.add(BtLinkState.disconnected);
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _plugin.disconnect();
    } finally {
      _linkStateCtrl.add(BtLinkState.disconnected);
    }
  }

  @override
  Future<void> writeLine(String data) async {
    await _plugin.write(data);
  }

  @override
  void dispose() {
    _linkStateCtrl.close();
    _deviceCtrl.close();
    _lineCtrl.close();
    _errorCtrl.close();
  }
}

import 'dart:async';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart' as bc;
import 'bt_service.dart';
import '../constants.dart';

/// Android RFCOMM/SPP transport for an HC-05 connected to the STM32 rover.
///
/// The UI talks only to BtService; all plugin-specific behavior stays here.
class RealBtService implements BtService {
  final _plugin = BluetoothClassic();
  final _linkStateCtrl = StreamController<BtLinkState>.broadcast();
  final _deviceCtrl = StreamController<BtDevice>.broadcast();
  final _lineCtrl = StreamController<String>.broadcast();
  final _errorCtrl = StreamController<String>.broadcast();

  String _rxBuffer = '';
  bool _permissionsReady = false;
  bool _disposed = false;

  RealBtService() {
    _plugin.onDeviceDiscovered().listen((bc.Device d) {
      if (!_disposed) {
        _deviceCtrl.add(BtDevice(name: d.name ?? d.address, address: d.address));
      }
    });

    _plugin.onDeviceStatusChanged().listen((int status) {
      if (_disposed) return;
      if (status == bc.Device.connected) {
        _linkStateCtrl.add(BtLinkState.connected);
      } else if (status == bc.Device.disconnected) {
        _linkStateCtrl.add(BtLinkState.disconnected);
      }
    });

    _plugin.onDeviceDataReceived().listen((List<int> bytes) {
      if (_disposed) return;
      _rxBuffer += String.fromCharCodes(bytes);
      _drainLines();
    });
  }

  void _drainLines() {
    while (true) {
      final newline = _rxBuffer.indexOf('\n');
      if (newline < 0) break;

      final line = _rxBuffer.substring(0, newline).trim();
      _rxBuffer = _rxBuffer.substring(newline + 1);
      if (line.isNotEmpty) _lineCtrl.add(line);
    }

    // Prevent an unplugged/corrupt stream from growing without bound.
    if (_rxBuffer.length > 8192) {
      _rxBuffer = _rxBuffer.substring(_rxBuffer.length - 4096);
    }
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
        if (!_disposed) {
          _deviceCtrl.add(BtDevice(name: d.name ?? d.address, address: d.address));
        }
      }
      await _plugin.startScan();
    } catch (e) {
      _errorCtrl.add('Scan failed: $e');
      _linkStateCtrl.add(BtLinkState.disconnected);
    }
  }

  @override
  Future<void> stopScan() async {
    try {
      await _plugin.stopScan();
    } catch (_) {
      // Scan may already have stopped.
    }
  }

  @override
  Future<void> connect(BtDevice device) async {
    await _ensurePermissions();
    _linkStateCtrl.add(BtLinkState.connecting);
    try {
      await _plugin.connect(device.address, sppUuid);
      _linkStateCtrl.add(BtLinkState.connected);
    } catch (e) {
      _errorCtrl.add('Could not connect to ${device.name}: $e');
      _linkStateCtrl.add(BtLinkState.disconnected);
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _plugin.disconnect();
    } finally {
      if (!_disposed) _linkStateCtrl.add(BtLinkState.disconnected);
    }
  }

  @override
  Future<void> writeLine(String data) async {
    // The rover protocol is line-delimited. Do not rely on the caller to
    // remember the framing or STM32 commands can be concatenated/ignored.
    final framed = data.endsWith('\n') ? data : '$data\r\n';
    await _plugin.write(framed);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _linkStateCtrl.close();
    _deviceCtrl.close();
    _lineCtrl.close();
    _errorCtrl.close();
  }
}

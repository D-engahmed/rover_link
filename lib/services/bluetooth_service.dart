import 'dart:async';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'rover_link_protocol.dart';

enum RoverLinkStatus { disconnected, scanning, connecting, connected, error }

/// Owns the classic-Bluetooth (SPP) connection to the HC-05 module.
///
/// Android only: the HC-05 is a classic-Bluetooth serial module, and iOS
/// does not allow third-party apps to open the classic SPP profile (Apple
/// requires MFi hardware certification for that). If you need this app to
/// run on iOS, the rover-side fix is to swap the HC-05 for a BLE module
/// (e.g. HM-10, or the STM32's own BLE if it has one) — the phone-side fix
/// alone can't work around Apple's restriction.
class RoverConnection {
  RoverConnection();

  final _bt = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  StreamSubscription<Uint8ListLike>? _sub;
  final StringBuffer _incomingBuffer = StringBuffer();

  final _statusController = StreamController<RoverLinkStatus>.broadcast();
  final _telemetryController = StreamController<RoverPacket>.broadcast();

  Stream<RoverLinkStatus> get status => _statusController.stream;
  Stream<RoverPacket> get telemetry => _telemetryController.stream;

  RoverLinkStatus _current = RoverLinkStatus.disconnected;
  RoverLinkStatus get currentStatus => _current;

  void _setStatus(RoverLinkStatus s) {
    _current = s;
    _statusController.add(s);
  }

  /// Returns previously-paired devices. The user must pair the HC-05 in the
  /// phone's Bluetooth settings first (default HC-05 PIN is usually 1234 or
  /// 0000) — this app only lists and connects, it doesn't do OS-level pairing.
  Future<List<BluetoothDevice>> pairedDevices() async {
    try {
      return await _bt.getBondedDevices();
    } catch (_) {
      return const [];
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    _setStatus(RoverLinkStatus.connecting);
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      _setStatus(RoverLinkStatus.connected);
      _sub = _connection!.input?.listen(
        _onData,
        onDone: () => _setStatus(RoverLinkStatus.disconnected),
        onError: (_) => _setStatus(RoverLinkStatus.error),
      );
      return true;
    } catch (_) {
      _setStatus(RoverLinkStatus.error);
      return false;
    }
  }

  void _onData(dynamic data) {
    // flutter_bluetooth_serial delivers raw bytes; decode and split on
    // newlines since the protocol is newline-delimited JSON.
    final chunk = utf8.decode(data as List<int>, allowMalformed: true);
    _incomingBuffer.write(chunk);
    final combined = _incomingBuffer.toString();
    final lines = combined.split('\n');
    // Keep the last (possibly incomplete) fragment buffered.
    _incomingBuffer
      ..clear()
      ..write(lines.removeLast());
    for (final line in lines) {
      final packet = RoverPacket.tryParse(line);
      if (packet != null) _telemetryController.add(packet);
    }
  }

  void sendCommand(String cmd, [Map<String, dynamic> extra = const {}]) {
    final conn = _connection;
    if (conn == null || !(conn.isConnected)) return;
    conn.output.add(utf8.encode(RoverPacket.encodeCommand(cmd, extra)));
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    await _connection?.finish();
    _connection = null;
    _setStatus(RoverLinkStatus.disconnected);
  }

  void dispose() {
    _sub?.cancel();
    _connection?.dispose();
    _statusController.close();
    _telemetryController.close();
  }
}

/// Small alias so this file doesn't hard-depend on the exact type
/// flutter_bluetooth_serial's `input` stream emits across versions.
typedef Uint8ListLike = List<int>;

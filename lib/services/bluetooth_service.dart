import 'dart:async';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'rover_link_protocol.dart';

enum RoverLinkStatus { disconnected, scanning, connecting, connected, error }

/// Owns the Bluetooth Classic (RFCOMM/SPP) connection to the HC-05 module.
///
/// Uses `flutter_classic_bluetooth` — actively maintained and built against
/// current Android tooling (AGP/Kotlin), unlike the older
/// `flutter_bluetooth_serial`, which no longer builds on recent Flutter/AGP
/// versions.
///
/// Full functionality on Android, Windows, macOS, Linux. On iOS, Bluetooth
/// Classic is restricted to MFi-certified accessories, so a plain HC-05
/// can't be reached from this app on iOS — the rover side would need a BLE
/// module instead (e.g. HM-10) to support iOS.
class RoverConnection {
  RoverConnection() : _bt = FlutterClassicBluetooth();

  final FlutterClassicBluetooth _bt;
  BtcLink? _link;
  StreamSubscription? _stateSub;
  StreamSubscription<String>? _lineSub;

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

  /// Devices already paired at the OS level. Pair the HC-05 in the phone's
  /// Bluetooth settings first (default PIN is usually 1234 or 0000) — this
  /// only lists/connects, it doesn't do OS-level pairing.
  Future<List<BtcDevice>> pairedDevices() async {
    try {
      return await _bt.getPairedDevices();
    } catch (_) {
      return const [];
    }
  }

  /// Connects with auto-reconnect (exponential backoff) since a robot link
  /// over classic Bluetooth is exactly the "long-lived link to a flaky
  /// device" case the package's `connectWithReconnect` is meant for.
  Future<bool> connect(BtcDevice device) async {
    _setStatus(RoverLinkStatus.connecting);
    await _teardown();
    try {
      final link = _bt.connectWithReconnect(
        address: device.address,
        policy: const BtcReconnectPolicy(
          initialBackoff: Duration(seconds: 1),
          maxBackoff: Duration(seconds: 15),
        ),
      );
      _link = link;
      _stateSub = link.state.listen((s) {
        final name = s.name.toLowerCase();
        if (name == 'connected') {
          _setStatus(RoverLinkStatus.connected);
        } else if (name.contains('connecting')) {
          // covers both "connecting" and "reconnecting"
          _setStatus(RoverLinkStatus.connecting);
        } else if (name.contains('disconnect')) {
          _setStatus(RoverLinkStatus.disconnected);
        } else {
          _setStatus(RoverLinkStatus.error);
        }
      });
      _lineSub = link.input.lines().listen((line) {
        final packet = RoverPacket.tryParse(line);
        if (packet != null) _telemetryController.add(packet);
      });
      return true;
    } catch (_) {
      _setStatus(RoverLinkStatus.error);
      return false;
    }
  }

  void sendCommand(String cmd, [Map<String, dynamic> extra = const {}]) {
    final link = _link;
    if (link == null || !link.isConnected) return;
    link.sendString(RoverPacket.encodeCommand(cmd, extra));
  }

  Future<void> _teardown() async {
    await _stateSub?.cancel();
    await _lineSub?.cancel();
    _stateSub = null;
    _lineSub = null;
  }

  Future<void> disconnect() async {
    await _teardown();
    await _link?.close();
    _link = null;
    _setStatus(RoverLinkStatus.disconnected);
  }

  void dispose() {
    _teardown();
    _link?.close();
    _statusController.close();
    _telemetryController.close();
  }
}

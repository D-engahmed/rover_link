import 'dart:async';

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

enum BluetoothConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  ready,
  failed,
}

class BluetoothService {
  final FlutterClassicBluetooth bluetooth = FlutterClassicBluetooth();

  BtcConnection? _connection;
  BluetoothConnectionState _state = BluetoothConnectionState.disconnected;
  String? _connectedAddress;
  String? _lastError;
  bool _connecting = false;

  BluetoothConnectionState get state => _state;
  bool get isConnected => _connection != null &&
      (_state == BluetoothConnectionState.connected ||
          _state == BluetoothConnectionState.ready);
  bool get isReady => _state == BluetoothConnectionState.ready;
  String? get connectedAddress => _connectedAddress;
  String? get lastError => _lastError;

  Future<bool> isBluetoothSupported() async {
    try {
      return await bluetooth.isSupported();
    } catch (e) {
      _setFailed('Bluetooth support check failed: $e');
      return false;
    }
  }

  Future<bool> isBluetoothEnabled() async {
    try {
      return await bluetooth.isEnabled();
    } catch (e) {
      _setFailed('Bluetooth state check failed: $e');
      return false;
    }
  }

  Future<List<BtcDevice>> scanDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _state = BluetoothConnectionState.scanning;
    _lastError = null;

    try {
      if (!await isBluetoothSupported()) {
        throw Exception('Bluetooth is not supported on this device');
      }
      if (!await isBluetoothEnabled()) {
        throw Exception('Bluetooth is disabled');
      }

      final devices = await bluetooth.scan(timeout: timeout);
      _state = BluetoothConnectionState.disconnected;
      return devices;
    } catch (e) {
      _setFailed('Bluetooth scan failed: $e');
      rethrow;
    }
  }

  Future<BtcConnection> connectToDevice(
    String address, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    if (_connecting) {
      throw StateError('A Bluetooth connection attempt is already running');
    }

    _connecting = true;
    _state = BluetoothConnectionState.connecting;
    _lastError = null;

    try {
      if (!await isBluetoothSupported()) {
        throw Exception('Bluetooth is not supported');
      }
      if (!await isBluetoothEnabled()) {
        throw Exception('Bluetooth is disabled');
      }

      await _closeCurrentConnection();

      final newConnection =
          await bluetooth.connect(address: address).timeout(timeout);
      _connection = newConnection;
      _connectedAddress = address;
      _state = BluetoothConnectionState.connected;

      await Future<void>.delayed(const Duration(milliseconds: 150));
      _state = BluetoothConnectionState.ready;
      return newConnection;
    } on TimeoutException {
      await _closeCurrentConnection();
      _state = BluetoothConnectionState.disconnected;
      _lastError = 'Connection timeout';
      throw Exception(
        'Bluetooth connection timed out after ${timeout.inSeconds}s',
      );
    } catch (e) {
      await _closeCurrentConnection();
      _state = BluetoothConnectionState.disconnected;
      _lastError = e.toString();
      throw Exception('Failed to connect to $address: $e');
    } finally {
      _connecting = false;
    }
  }

  Future<void> sendCommand(String command) async {
    final connection = _connection;
    if (connection == null || !isReady) {
      throw StateError('Bluetooth is not ready. State: $_state');
    }

    if (command.length != 1) {
      throw ArgumentError(
        'Rover command must be exactly one byte, received: "$command"',
      );
    }

    try {
      // IMPORTANT: the STM32 firmware consumes one command byte at a time.
      // Do not append CR/LF here. CR/LF would become extra commands and be
      // reported as UNKNOWN_COMMAND by App_ControlTask().
      await connection.output.writeString(command);
      await connection.output.allSent;
    } catch (e) {
      await _handleSocketFailure(e);
      throw Exception('Bluetooth send failed: $e');
    }
  }

  Stream<String> receiveMessages() {
    final connection = _connection;
    if (connection == null || !isConnected) {
      throw StateError('Bluetooth is not connected');
    }

    return connection.input.lines().handleError((Object error) async {
      await _handleSocketFailure(error);
    });
  }

  Future<void> disconnect() async {
    await _closeCurrentConnection();
    _connectedAddress = null;
    _lastError = null;
    _state = BluetoothConnectionState.disconnected;
  }

  Future<void> _handleSocketFailure(Object error) async {
    _lastError = error.toString();
    await _closeCurrentConnection();
    _state = BluetoothConnectionState.disconnected;
  }

  Future<void> _closeCurrentConnection() async {
    final connection = _connection;
    _connection = null;
    if (connection == null) return;
    try {
      await connection.finish();
    } catch (_) {}
  }

  void _setFailed(String error) {
    _lastError = error;
    _state = BluetoothConnectionState.failed;
  }

  Future<void> testConnection(String address) async {
    final connection = await connectToDevice(address);
    // Intentionally no production logging here.
    if (connection.isConnected) return;
  }

  Future<void> testScan() async {
    await scanDevices();
  }
}

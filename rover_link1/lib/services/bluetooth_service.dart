  import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

class BluetoothService {
  final FlutterClassicBluetooth bluetooth =
      FlutterClassicBluetooth();
      BtcConnection? connection;

  Future<bool> isBluetoothSupported() async {
    return await bluetooth.isSupported();
  }

  Future<bool> isBluetoothEnabled() async {
    return await bluetooth.isEnabled();
  }

  Future<List<BtcDevice>> scanDevices() async {
    return await bluetooth.scan(
      timeout: const Duration(seconds: 8),
    );
  }
   Future<BtcConnection> connectToDevice(String address) async {
  connection = await bluetooth.connect(
    address: address,
  );

  return connection!;
}
   Future<void> sendCommand(String command) async {
  if (connection == null) {
    throw Exception('Bluetooth device is not connected');
  }

   await connection!.output.writeString(command);
}
 Stream<String> receiveMessages() {
  if (connection == null) {
    throw Exception('Bluetooth device is not connected');
  }

  return connection!.input.lines();
}
   bool get isConnected => connection != null;

   Future<void> testConnection(String address) async {
  try {
    final connection = await connectToDevice(address);

    print('===== BLUETOOTH CONNECT =====');
    print('Connected successfully!');
    print('Address: $address');
    print('Connection: $connection');
    print('=============================');
  } catch (e) {
    print('===== BLUETOOTH CONNECT =====');
    print('Connection failed!');
    print('Error: $e');
    print('=============================');
  }
} 
Future<void> disconnectFromDevice(BtcConnection connection) async {
  await connection.finish();

  print('===== BLUETOOTH DISCONNECT =====');
  print('Disconnected successfully!');
  print('===============================');
}

  Future<void> testScan() async {
    final devices = await scanDevices();

    print('===== BLUETOOTH SCAN =====');
    print('Devices found: ${devices.length}');

    for (final device in devices) {
      print('Device: ${device.name}');
      print('Address: ${device.address}');
    }

    print('==========================');
  }
}
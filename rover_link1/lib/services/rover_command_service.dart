 import 'bluetooth_service.dart';

class RoverCommandService {
  final BluetoothService bluetoothService;

  RoverCommandService(this.bluetoothService);

  Future<void> manualMode() async {
    await bluetoothService.sendCommand('M');
  }

  Future<void> autopilotMode() async {
    await bluetoothService.sendCommand('F');
  }

  Future<void> moveForward() async {
    await bluetoothService.sendCommand('W');
  }

  Future<void> moveBackward() async {
    await bluetoothService.sendCommand('S');
  }

  Future<void> turnLeft() async {
    await bluetoothService.sendCommand('A');
  }

  Future<void> turnRight() async {
    await bluetoothService.sendCommand('D');
  }

  Future<void> spinLeft() async {
    await bluetoothService.sendCommand('Q');
  }

  Future<void> spinRight() async {
    await bluetoothService.sendCommand('E');
  }
Future<void> stop() async {
  await bluetoothService.sendCommand('P');
}
   Future<void> setSpeed(int speed) async {
  if (speed < 0 || speed > 100) {
    throw ArgumentError('Speed must be between 0 and 100');
  }

  if (speed == 0) {
    await bluetoothService.sendCommand('P');
    return;
  }

  if (speed == 100) {
    await bluetoothService.sendCommand('0');
    return;
  }

  final int level = (speed / 10).round();
  await bluetoothService.sendCommand(level.toString());
}

Future<void> increaseSpeed() async {
  await bluetoothService.sendCommand('+');
}

Future<void> decreaseSpeed() async {
  await bluetoothService.sendCommand('-');
}
}
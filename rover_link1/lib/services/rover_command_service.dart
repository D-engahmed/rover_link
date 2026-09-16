import 'dart:async';

import '../models/command_trace.dart';
import 'bluetooth_service.dart';

class RoverCommandService {
  final BluetoothService bluetoothService;
  final StreamController<CommandTrace> _traces = StreamController<CommandTrace>.broadcast();

  RoverCommandService(this.bluetoothService);

  Stream<CommandTrace> get traces => _traces.stream;

  Future<void> sendCommand(
    String action,
    String wireCommand, {
    CommandSource source = CommandSource.human,
  }) async {
    _traces.add(CommandTrace(timestamp: DateTime.now(), source: source, stage: CommandStage.proposed, action: action, wireCommand: wireCommand));
    try {
      _traces.add(CommandTrace(timestamp: DateTime.now(), source: source, stage: CommandStage.approved, action: action, wireCommand: wireCommand));
      _traces.add(CommandTrace(timestamp: DateTime.now(), source: source, stage: CommandStage.queued, action: action, wireCommand: wireCommand));
      final stopwatch = Stopwatch()..start();
      await bluetoothService.sendCommand(wireCommand);
      stopwatch.stop();
      _traces.add(CommandTrace(timestamp: DateTime.now(), source: source, stage: CommandStage.sent, action: action, wireCommand: wireCommand, latencyMs: stopwatch.elapsedMilliseconds));
    } catch (e) {
      _traces.add(CommandTrace(timestamp: DateTime.now(), source: source, stage: CommandStage.failed, action: action, wireCommand: wireCommand, reason: e.toString()));
      rethrow;
    }
  }

  Future<void> manualMode() => sendCommand('MANUAL MODE', 'M', source: CommandSource.system);
  Future<void> autopilotMode() => sendCommand('AUTONOMOUS MODE', 'F', source: CommandSource.system);

  // Every firmware mode transition first sends STOP. This is intentionally
  // serialized so an old control loop cannot keep driving after a switch.
  Future<void> enterManualMode() async {
    await stop(source: CommandSource.system);
    await manualMode();
  }

  Future<void> enterAutonomousMode() async {
    await stop(source: CommandSource.system);
    await autopilotMode();
  }

  Future<void> moveForward({CommandSource source = CommandSource.human}) => sendCommand('FORWARD', 'W', source: source);
  Future<void> moveBackward({CommandSource source = CommandSource.human}) => sendCommand('BACKWARD', 'S', source: source);
  Future<void> turnLeft({CommandSource source = CommandSource.human}) => sendCommand('LEFT', 'A', source: source);
  Future<void> turnRight({CommandSource source = CommandSource.human}) => sendCommand('RIGHT', 'D', source: source);
  Future<void> spinLeft({CommandSource source = CommandSource.human}) => sendCommand('SPIN LEFT', 'Q', source: source);
  Future<void> spinRight({CommandSource source = CommandSource.human}) => sendCommand('SPIN RIGHT', 'E', source: source);
  Future<void> stop({CommandSource source = CommandSource.system}) => sendCommand('STOP', 'P', source: source);

  Future<void> setSpeed(int speed, {CommandSource source = CommandSource.human}) async {
    if (speed < 0 || speed > 100) throw ArgumentError('Speed must be between 0 and 100');
    if (speed == 0) return stop(source: source);
    final level = speed == 100 ? 0 : (speed / 10).round().clamp(1, 9);
    await sendCommand('SPEED $speed%', level.toString(), source: source);
  }

  Future<void> increaseSpeed({CommandSource source = CommandSource.human}) => sendCommand('SPEED UP', '+', source: source);
  Future<void> decreaseSpeed({CommandSource source = CommandSource.human}) => sendCommand('SPEED DOWN', '-', source: source);

  void dispose() => _traces.close();
}

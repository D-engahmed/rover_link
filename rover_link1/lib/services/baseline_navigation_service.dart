import '../models/rover_telemetry.dart';
import 'rover_command_service.dart';

class BaselineNavigationService {
  static const double emergencyStopCm = 15;
  static const double obstacleCm = 40;

  final RoverCommandService commands;

  BaselineNavigationService(this.commands);

  String decide(RoverTelemetry state) {
    final front = state.frontDistanceCm;
    if (front == null || front <= emergencyStopCm) return 'STOP';
    if (front > obstacleCm) return 'FORWARD';

    final left = state.leftDistanceCm ?? 0;
    final right = state.rightDistanceCm ?? 0;
    if (left <= emergencyStopCm && right <= emergencyStopCm) return 'STOP';
    return left > right ? 'LEFT' : 'RIGHT';
  }

  Future<String> step(RoverTelemetry state) async {
    final action = decide(state);
    switch (action) {
      case 'FORWARD':
        await commands.moveForward();
        break;
      case 'LEFT':
        await commands.turnLeft();
        break;
      case 'RIGHT':
        await commands.turnRight();
        break;
      default:
        await commands.stop();
    }
    return action;
  }
}

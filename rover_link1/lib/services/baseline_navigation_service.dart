import '../models/rover_telemetry.dart';
import 'rover_command_service.dart';

class BaselineNavigationService {
  static const double emergencyStopCm = 15;
  static const double obstacleCm = 40;
  static const double centerMinDeg = 80;
  static const double centerMaxDeg = 100;

  final RoverCommandService commands;
  double _leftClearanceCm = 0;
  double _rightClearanceCm = 0;
  String _lastAction = 'STOP';
  bool _centerDecisionPending = false;

  BaselineNavigationService(this.commands);

  String decide(RoverTelemetry state) {
    final front = state.frontDistanceCm;
    if (front == null || front <= emergencyStopCm) return 'STOP';
    if (front > obstacleCm) return 'FORWARD';
    if (_leftClearanceCm <= emergencyStopCm && _rightClearanceCm <= emergencyStopCm) return 'STOP';
    if (_leftClearanceCm > _rightClearanceCm) return 'LEFT';
    if (_rightClearanceCm > _leftClearanceCm) return 'RIGHT';
    return 'STOP';
  }

  Future<String?> step(RoverTelemetry state) async {
    final angle = state.targetAngleDeg;
    final distance = state.frontDistanceCm;
    if (angle == null || distance == null) return null;

    if (angle > centerMaxDeg) {
      _leftClearanceCm = _leftClearanceCm == 0 ? distance : (_leftClearanceCm * .7 + distance * .3);
    } else if (angle < centerMinDeg) {
      _rightClearanceCm = _rightClearanceCm == 0 ? distance : (_rightClearanceCm * .7 + distance * .3);
    }

    if (angle >= centerMinDeg && angle <= centerMaxDeg && !_centerDecisionPending) {
      _centerDecisionPending = true;
      _lastAction = decide(state);
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        _centerDecisionPending = false;
      });
    }

    switch (_lastAction) {
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
    return _lastAction;
  }
}

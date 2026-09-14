import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/bt_service.dart';
import '../services/vision_service.dart';
import '../constants.dart';

enum DriveMode { manual, follow }
enum BearingSource { gradientSearch, compassImu, camera }

class LogEntry {
  final DateTime time;
  final String text;
  final bool emphasis;
  LogEntry(this.text, {this.emphasis = false}) : time = DateTime.now();
}

class RoverState extends ChangeNotifier {
  final BtService bt;
  VisionService? _vision;
  StreamSubscription<PersonSighting>? _visionSub;

  RoverState(this.bt) {
    _linkSub = bt.linkState.listen(_onLinkState);
    _deviceSub = bt.deviceDiscovered.listen((d) {
      if (!discoveredDevices.any((x) => x.address == d.address)) {
        discoveredDevices.add(d);
        notifyListeners();
      }
    });
    _lineSub = bt.linesReceived.listen(_onLine);
    _errorSub = bt.connectionError.listen((e) {
      lastConnectError = e;
      notifyListeners();
    });
  }

  late final StreamSubscription _linkSub;
  late final StreamSubscription _deviceSub;
  late final StreamSubscription _lineSub;
  late final StreamSubscription _errorSub;

  BtLinkState linkState = BtLinkState.disconnected;
  List<BtDevice> discoveredDevices = [];
  String? lastConnectError;
  BtDevice? connectedDevice;
  bool get connected => linkState == BtLinkState.connected;

  Future<void> startScan() async {
    discoveredDevices = [];
    lastConnectError = null;
    notifyListeners();
    await bt.startScan();
  }

  Future<void> connectTo(BtDevice device) async {
    connectedDevice = device;
    lastConnectError = null;
    notifyListeners();
    await bt.connect(device);
  }

  Future<void> disconnectRover() async {
    if (mode == DriveMode.follow) await setMode(DriveMode.manual);
    await bt.disconnect();
  }

  void _onLinkState(BtLinkState s) {
    linkState = s;
    if (s == BtLinkState.connected) {
      _pushTerm(LogEntry(
        'Connected${connectedDevice != null ? ' to ${connectedDevice!.name} (${connectedDevice!.address})' : ''}, 9600 baud.',
      ));
      nearestObstacleCm = 160;
    } else if (s == BtLinkState.disconnected) {
      _pushTerm(LogEntry('Disconnected.'));
      nearestObstacleCm = null;
      // A broken link must never leave the rover logically driving.
      if (mode == DriveMode.follow) mode = DriveMode.manual;
      doorOpen = false;
    }
    notifyListeners();
  }

  double? nearestObstacleCm;
  bool estopped = false;

  String get safetyState {
    if (estopped) return 'crit';
    if (nearestObstacleCm == null) return 'ok';
    if (nearestObstacleCm! < obstacleCriticalCm) return 'crit';
    if (nearestObstacleCm! < obstacleCautionCm) return 'caution';
    return 'ok';
  }

  void toggleEstop([bool? forceOn]) {
    estopped = forceOn ?? !estopped;
    if (estopped) {
      // Best effort: the stop command is sent even though drive() is locked.
      unawaited(_sendRawStop());
      _pushTerm(LogEntry('Motors stopped. Drive input locked until reset.'));
    } else {
      _pushTerm(LogEntry('Reset. Drive input re-armed.'));
    }
    notifyListeners();
  }

  Future<void> _sendRawStop() async {
    if (!connected) return;
    try {
      await bt.writeLine('CMD:$cmdStop');
    } catch (e) {
      _errorLog('E-stop transmit failed: $e');
    }
  }

  DriveMode mode = DriveMode.manual;

  Future<void> setMode(DriveMode m) async {
    if (m == mode) return;
    if (m == DriveMode.follow) {
      if (!connected) {
        _pushAi(LogEntry('Cannot start — connect the rover first.'));
        notifyListeners();
        return;
      }
      if (estopped) {
        _pushAi(LogEntry('Cannot start — motors are stopped. Reset first.'));
        notifyListeners();
        return;
      }
      distanceHistoryCm = [];
      _prevDistCm = null;
      _pushAi(LogEntry('Follow me started.'));
      if (bearingSource == BearingSource.camera) {
        try {
          await _vision?.start();
        } catch (e) {
          steeringText = 'CAMERA ERROR';
          _pushAi(LogEntry('Camera unavailable: $e'));
        }
      }
    } else if (mode == DriveMode.follow) {
      _pushAi(LogEntry('Follow me stopped. Manual control only.'));
      await _vision?.stop();
      if (doorOpen) await closeDoor();
      await _sendRawStop();
    }
    mode = m;
    notifyListeners();
  }

  int speedPercent = 60;
  String lastCommand = '$cmdStop · STOP';

  Future<void> drive(String code, String label) async {
    if (!connected || estopped) return;
    // Never allow movement through the UI while the obstacle safety state is critical.
    if (nearestObstacleCm != null && nearestObstacleCm! < obstacleCriticalCm && code != cmdStop) {
      toggleEstop(true);
      return;
    }
    lastCommand = '$code · $label';
    await bt.writeLine('CMD:$code');
    _pushTerm(LogEntry('TX CMD:$code'));
    notifyListeners();
  }

  Future<void> setSpeed(int v) async {
    speedPercent = v.clamp(0, 100);
    final pwm = (speedPercent / 100 * 255).round();
    if (connected && !estopped) {
      await bt.writeLine('PWM:$pwm');
      _pushTerm(LogEntry('TX PWM:$pwm'));
    }
    notifyListeners();
  }

  Future<void> sendMacro(String cmd) async {
    if (!connected) {
      _pushTerm(LogEntry('Not connected.'));
      notifyListeners();
      return;
    }
    if (cmd != 'STOP' && estopped) return;
    await bt.writeLine(cmd);
    _pushTerm(LogEntry('TX $cmd'));
    if (cmd == 'STOP') toggleEstop(true);
    notifyListeners();
  }

  Future<void> sendCustom(String raw) async {
    if (raw.isEmpty || !connected || estopped) return;
    await bt.writeLine(raw);
    _pushTerm(LogEntry('TX $raw'));
    notifyListeners();
  }

  bool doorOpen = false;

  Future<void> openDoor() async {
    if (doorOpen || !connected || estopped) return;
    doorOpen = true;
    try {
      await bt.writeLine(cmdDoorOpen);
      _pushTerm(LogEntry('TX $cmdDoorOpen'));
      _pushAi(LogEntry(
        'Person centered and facing the rover, ${nearestObstacleCm?.round()}cm out — opening door.',
        emphasis: true,
      ));
    } catch (e) {
      doorOpen = false;
      _errorLog('Door-open transmit failed: $e');
    }
    notifyListeners();
  }

  Future<void> closeDoor() async {
    if (!doorOpen) return;
    doorOpen = false;
    if (connected) {
      try {
        await bt.writeLine(cmdDoorClose);
        _pushTerm(LogEntry('TX $cmdDoorClose'));
      } catch (e) {
        _errorLog('Door-close transmit failed: $e');
      }
    }
    notifyListeners();
  }

  BearingSource bearingSource = BearingSource.gradientSearch;
  String steeringText = '—';
  double? targetDistanceCm;
  List<double> distanceHistoryCm = [];
  double? _prevDistCm;
  String _searchDir = 'LEFT';
  PersonSighting lastSighting = PersonSighting.none;

  void attachVision(VisionService vision) {
    _visionSub?.cancel();
    _vision = vision;
    _visionSub = vision.sightings.listen(_onSighting);
  }

  void setBearingSource(BearingSource s) {
    bearingSource = s;
    if (s == BearingSource.compassImu) {
      steeringText = '— (no IMU installed)';
      unawaited(_vision?.stop());
      _pushAi(LogEntry('Switched to Compass/IMU mode — no heading sensor on the board.'));
    } else if (s == BearingSource.camera) {
      steeringText = mode == DriveMode.follow ? 'SEARCHING — no one in frame' : '—';
      _pushAi(LogEntry('Switched to camera mode — steering off the detected face, door trigger armed.'));
      if (mode == DriveMode.follow) {
        unawaited(_startVisionSafely());
      }
    } else {
      steeringText = mode == DriveMode.follow ? 'HOLD' : '—';
      unawaited(_vision?.stop());
    }
    notifyListeners();
  }

  Future<void> _startVisionSafely() async {
    try {
      await _vision?.start();
    } catch (e) {
      steeringText = 'CAMERA ERROR';
      _pushAi(LogEntry('Camera unavailable: $e'));
      notifyListeners();
    }
  }

  void _onSighting(PersonSighting s) {
    lastSighting = s;
    if (mode == DriveMode.follow && bearingSource == BearingSource.camera) {
      if (!s.present) {
        steeringText = 'SEARCHING — no one in frame';
        if (doorOpen) unawaited(closeDoor());
      } else {
        steeringText = s.bearingFrac.abs() < centeredBearingThreshold
            ? 'HOLD — centered'
            : (s.bearingFrac < 0 ? 'TURN LEFT' : 'TURN RIGHT');
        _maybeOpenDoor();
      }
    }
    notifyListeners();
  }

  void _maybeOpenDoor() {
    if (doorOpen || !connected || estopped) return;
    final centered = lastSighting.present &&
        lastSighting.bearingFrac.abs() < centeredBearingThreshold &&
        lastSighting.facingCamera;
    final closeEnough = nearestObstacleCm != null && nearestObstacleCm! <= doorApproachCm;
    if (centered && closeEnough) unawaited(openDoor());
  }

  final List<LogEntry> terminalLog = [];
  final List<LogEntry> aiLog = [];
  String consolePreview = 'idle';

  void _pushTerm(LogEntry e) {
    terminalLog.add(e);
    if (terminalLog.length > 300) terminalLog.removeAt(0);
    consolePreview = e.text;
  }

  void _pushAi(LogEntry e) {
    aiLog.add(e);
    if (aiLog.length > 300) aiLog.removeAt(0);
  }

  void _errorLog(String message) {
    _pushTerm(LogEntry(message, emphasis: true));
  }

  void _onLine(String line) {
    final normalized = line.trim();
    if (normalized.isEmpty) return;
    _pushTerm(LogEntry('RX $normalized'));

    if (normalized.startsWith('+US:')) {
      final v = double.tryParse(
        normalized.substring(4).replaceAll(RegExp(r'cm$', caseSensitive: false), '').trim(),
      );
      if (v != null) {
        nearestObstacleCm = v;
        if (v < obstacleCriticalCm) {
          toggleEstop(true);
        } else if (bearingSource == BearingSource.camera) {
          _maybeOpenDoor();
        }
      }
    } else if (normalized.startsWith('+DIST:')) {
      final v = double.tryParse(
        normalized.substring(6).replaceAll(RegExp(r'm$', caseSensitive: false), '').trim(),
      );
      if (v != null) _handleDistanceSample(v * 100);
    }
    notifyListeners();
  }

  void _handleDistanceSample(double distCm) {
    targetDistanceCm = distCm;
    distanceHistoryCm.add(distCm);
    if (distanceHistoryCm.length > 24) distanceHistoryCm.removeAt(0);

    if (mode == DriveMode.follow && bearingSource == BearingSource.gradientSearch) {
      if (_prevDistCm != null) {
        if (distCm < _prevDistCm! - 5) {
          steeringText = 'HOLD — closing in';
          if (aiLog.isEmpty || aiLog.last.text != 'Signal strengthening, holding heading.') {
            _pushAi(LogEntry('Signal strengthening, holding heading.', emphasis: true));
          }
        } else if (distCm > _prevDistCm! + 5) {
          _searchDir = _searchDir == 'LEFT' ? 'RIGHT' : 'LEFT';
          steeringText = 'SEARCH $_searchDir';
          _pushAi(LogEntry(
            'Signal weakening — turning ${_searchDir.toLowerCase()} to reacquire.',
            emphasis: true,
          ));
        } else {
          steeringText = 'HOLD';
        }
      }
    }
    _prevDistCm = distCm;
  }

  @override
  void dispose() {
    _linkSub.cancel();
    _deviceSub.cancel();
    _lineSub.cancel();
    _errorSub.cancel();
    _visionSub?.cancel();
    _vision?.dispose();
    bt.dispose();
    super.dispose();
  }
}

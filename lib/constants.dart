/// Demo transport is opt-in so a production/test phone does not silently
/// pretend to be connected to an HC-05. Enable it with:
/// flutter run --dart-define=ROVER_DEMO=true
const bool useDemoBluetooth = bool.fromEnvironment(
  'ROVER_DEMO',
  defaultValue: false,
);

/// Standard SPP UUID used by HC-05 modules in serial mode.
const String sppUuid = '00001101-0000-1000-8000-00805f9b34fb';

/// IMPORTANT: these command tokens are still the protocol expected by the
/// current app prototype. They are not a verified STM32 firmware contract.
/// Keep this file as the single source of truth until the firmware parser is
/// available and the wire protocol can be verified end-to-end.
const String cmdForward = 'F';
const String cmdBack = 'B';
const String cmdLeft = 'L';
const String cmdRight = 'R';
const String cmdStop = 'S';
const String cmdDoorOpen = 'DOOR_OPEN';
const String cmdDoorClose = 'DOOR_CLOSE';

/// Safety thresholds in centimetres.
const double obstacleCriticalCm = 25;
const double obstacleCautionCm = 60;
const double doorApproachCm = 100;

/// Camera bearing tolerance: 0 = centre, +/-1 = frame edge.
const double centeredBearingThreshold = 0.12;

/// Maximum absolute head yaw accepted as "facing the rover".
const double facingYawThresholdDeg = 20;

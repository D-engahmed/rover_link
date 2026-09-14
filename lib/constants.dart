/// Set to false once you're testing on a real Android device with the rover
/// powered on. true  = DemoBtService (simulated devices + telemetry, runs
/// anywhere, no hardware). false = RealBtService (bluetooth_classic, Android
/// only). See services/bt_service.dart and services/real_bt_service.dart.
const bool useDemoBluetooth = true;

/// Standard SPP UUID most HC-05 modules advertise by default. Only change
/// this if your firmware/module configuration uses a different service UUID.
const String sppUuid = '00001101-0000-1000-8000-00805f9b34fb';

/// PLACEHOLDER single-character drive commands, carried over from the HTML
/// prototype. These are NOT confirmed against your STM32 UART parser — swap
/// them for your real protocol before relying on manual drive over a real
/// link. See README.md.
const String cmdForward = 'F';
const String cmdBack = 'B';
const String cmdLeft = 'L';
const String cmdRight = 'R';
const String cmdStop = 'S';

/// Door actuator (servo on a PWM pin, per what you confirmed). PLACEHOLDER
/// command strings — you said you'd give the real angle/command values, so
/// treat these as stand-ins until then, same as the drive commands above.
const String cmdDoorOpen = 'DOOR_OPEN';
const String cmdDoorClose = 'DOOR_CLOSE';

/// Safety-strip thresholds, in centimetres, for the ultrasonic obstacle
/// reading. Below [obstacleCriticalCm] the app latches the e-stop itself.
const double obstacleCriticalCm = 25;
const double obstacleCautionCm = 60;

/// Distance (ultrasonic, cm) at which the door-open trigger fires, once the
/// person is centered and facing the camera. ~1m per what you described —
/// tune once you can test the actual approach distance you want.
const double doorApproachCm = 100;

/// How far off-center (as a fraction of frame width, 0=dead center,
/// 1=edge of frame) the detected face can be before we call it "centered"
/// for the purposes of the door trigger.
const double centeredBearingThreshold = 0.12;

/// Head yaw (degrees) within which we call the person "facing the camera".
/// ML Kit's headEulerAngleY: 0 = facing camera, larger = turned away.
const double facingYawThresholdDeg = 20;

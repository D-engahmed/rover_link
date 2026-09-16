import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/splash_screen.dart';
import 'screens/drive_screen.dart';
import 'screens/home_screen.dart';
import 'screens/radar_screen.dart';
import 'screens/ai_screen.dart';
import 'screens/settings_screen.dart';

import 'theme/rover_colors.dart';

import 'services/bluetooth_service.dart';
import 'services/rover_command_service.dart';
import 'services/rover_telemetry_service.dart';
import 'services/rover_dataset_service.dart';
import 'services/rover_ai_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: RoverColors.navBarBackground,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const RoverApp());
}

class RoverApp extends StatelessWidget {
  const RoverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rover Link',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: RoverColors.background,
        colorScheme: const ColorScheme.dark(
          primary: RoverColors.radarGreen,
          secondary: RoverColors.targetCyan,
          surface: RoverColors.cardBackground,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: RoverColors.background,
          elevation: 0,
        ),
      ),
      home: const AppStartScreen(),
    );
  }
}

class AppStartScreen extends StatefulWidget {
  const AppStartScreen({super.key});

  @override
  State<AppStartScreen> createState() => _AppStartScreenState();
}

class _AppStartScreenState extends State<AppStartScreen> {
  void _openHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/main'),
        builder: (_) => const MainNavigationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen(onFinished: _openHome);
  }
}

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final BluetoothService bluetoothService = BluetoothService();

  late final RoverCommandService roverCommandService;
  late final RoverTelemetryService roverTelemetryService;
  late final RoverDatasetService roverDatasetService;
  late final RoverAiService roverAiService;

  late int _currentIndex;
  bool _manualTransitionBusy = false;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;

    roverCommandService = RoverCommandService(bluetoothService);
    roverTelemetryService = RoverTelemetryService(bluetoothService);
    roverDatasetService = RoverDatasetService();

    roverAiService = RoverAiService(
      telemetryService: roverTelemetryService,
      commands: roverCommandService,
    );
  }

  Future<void> _enterManualMode() async {
    if (_manualTransitionBusy || !bluetoothService.isReady) return;
    _manualTransitionBusy = true;

    try {
      // Stop the phone AI loop first. RoverAiService.stop() waits for an
      // in-flight AI command before returning, so a late W/A/D packet cannot
      // arrive after the manual-mode command.
      await roverAiService.stop();

      // Firmware transition is serialized as STOP -> MANUAL MODE.
      await roverCommandService.enterManualMode();
    } finally {
      _manualTransitionBusy = false;
    }
  }

  void _onNavTap(int index) {
    if (index < 0 || index > 4) return;

    // Drive is the manual-control surface. Entering it must also change the
    // actual STM32 control mode; changing only the Flutter page is unsafe.
    if (index == 1) {
      _enterManualMode();
    }

    if (mounted) {
      setState(() => _currentIndex = index);
    }
  }

  Future<void> _onConnected() async {
    if (!bluetoothService.isReady) return;
    roverTelemetryService.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            onNavTap: _onNavTap,
            telemetryService: roverTelemetryService,
            bluetoothService: bluetoothService,
            commandService: roverCommandService,
            aiService: roverAiService,
          ),
          DriveScreen(
            onNavTap: _onNavTap,
            roverCommandService: roverCommandService,
          ),
          RadarScreen(
            onNavTap: _onNavTap,
            telemetryService: roverTelemetryService,
          ),
          AiScreen(
            onNavTap: _onNavTap,
            aiService: roverAiService,
            commandService: roverCommandService,
            telemetryService: roverTelemetryService,
            bluetoothService: bluetoothService,
          ),
          SettingsScreen(
            onNavTap: _onNavTap,
            bluetoothService: bluetoothService,
            onConnected: _onConnected,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    roverAiService.dispose();
    roverTelemetryService.dispose();
    roverCommandService.dispose();
    bluetoothService.disconnect();
    super.dispose();
  }
}

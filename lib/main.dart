import 'dart:async';
import 'package:flutter/material.dart';
import 'models/rover_state.dart';
import 'screens/ai_screen.dart';
import 'screens/drive_screen.dart';
import 'screens/home_screen.dart';
import 'screens/radar_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const RoverApp());
}

class RoverApp extends StatelessWidget {
  const RoverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Rover',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const RoverShell(),
    );
  }
}

/// Bottom-nav shell for the five top-level sections described in the UI
/// spec's information architecture: Home, Drive, Radar, AI, Settings.
class RoverShell extends StatefulWidget {
  const RoverShell({super.key});

  @override
  State<RoverShell> createState() => _RoverShellState();
}

class _RoverShellState extends State<RoverShell> {
  final RoverState _state = RoverState();
  int _index = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Placeholder telemetry feed so every screen is alive without hardware
    // attached. Swap this for the real BLE packet stream from the HC-05
    // link (see settings_screen.dart) when the rover is connected.
    _ticker = Timer.periodic(const Duration(seconds: 2), (_) => _state.simulateTick());
    _state.addListener(_refresh);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _state.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(state: _state, onChanged: _refresh),
      DriveScreen(state: _state, onChanged: _refresh),
      RadarScreen(state: _state),
      AiScreen(state: _state),
      SettingsScreen(state: _state, onChanged: _refresh),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.gamepad_outlined), label: 'Drive'),
          BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'Radar'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), label: 'AI'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

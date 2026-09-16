import 'dart:async';

import 'package:flutter/material.dart';

import '../models/radar_detection.dart';
import '../models/rover_telemetry.dart';
import '../services/bluetooth_service.dart';
import '../services/rover_telemetry_service.dart';
import '../theme/rover_colors.dart';
import '../widgets/radar_scope.dart';
import '../widgets/rover_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTap;
  final RoverTelemetryService telemetryService;
  final BluetoothService bluetoothService;

  const HomeScreen({
    super.key,
    this.onNavTap,
    required this.telemetryService,
    required this.bluetoothService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<RoverTelemetry>? _subscription;
  RoverTelemetry? _telemetry;
  final Map<int, RadarDetection> _scan = {};
  String _selectedMode = 'MANUAL';

  @override
  void initState() {
    super.initState();
    _subscription = widget.telemetryService.telemetry.listen(_onTelemetry);
  }

  void _onTelemetry(RoverTelemetry value) {
    if (!mounted) return;
    final angle = value.radarAngleDeg ?? value.targetAngleDeg;
    final distance = value.ultrasonicDistanceCm ?? value.frontDistanceCm;
    setState(() {
      _telemetry = value;
      if (angle != null && distance != null && distance > 0) {
        final a = angle.round().clamp(0, 180);
        _scan[a] = RadarDetection(
          id: 'home-$a',
          name: 'ULTRASONIC',
          distance: distance / 100,
          bearing: a.toDouble(),
          type: DetectionType.obstacle,
          color: distance <= 40 ? RoverColors.obstacleRed : RoverColors.obstacleAmber,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final distance = _telemetry?.frontDistanceCm;
    final angle = _telemetry?.radarAngleDeg ?? _telemetry?.targetAngleDeg;
    final connected = widget.bluetoothService.isReady;

    return Scaffold(
      backgroundColor: RoverColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(connected),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    RadarScope(detections: _scan.values.toList(), maxDistance: 8),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _metric('DISTANCE', distance == null ? '--' : '${distance.toStringAsFixed(1)} cm')),
                      const SizedBox(width: 10),
                      Expanded(child: _metric('ANGLE', angle == null ? '--' : '${angle.toStringAsFixed(0)}°')),
                      const SizedBox(width: 10),
                      Expanded(child: _metric('MODE', _telemetry?.mode ?? '--')),
                    ]),
                    const SizedBox(height: 18),
                    _modeSelector(),
                    const SizedBox(height: 16),
                    _connectionCard(connected),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB42318)),
                        onPressed: () {},
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text('EMERGENCY STOP'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: RoverBottomNav(currentIndex: 0, onTap: widget.onNavTap),
    );
  }

  Widget _header(bool connected) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: RoverColors.cardBorder)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SMART ROVER', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            SizedBox(height: 2),
            Text('STM32 · HC-05 · HC-SR04', style: TextStyle(color: RoverColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: RoverColors.cardBackground, borderRadius: BorderRadius.circular(20), border: Border.all(color: RoverColors.cardBorder)),
            child: Text(connected ? 'ONLINE' : 'OFFLINE', style: TextStyle(color: connected ? RoverColors.radarGreen : RoverColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ]),
      );

  Widget _metric(String label, String value) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: RoverColors.cardBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: RoverColors.cardBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: RoverColors.textMuted, fontSize: 9)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _modeSelector() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: RoverColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: RoverColors.cardBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('CONTROL MODE', style: TextStyle(color: RoverColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: ['MANUAL', 'ASSISTED', 'FOLLOW ME', 'AUTONOMOUS'].map((mode) => ChoiceChip(label: Text(mode), selected: _selectedMode == mode, onSelected: (_) => setState(() => _selectedMode = mode))).toList()),
        ]),
      );

  Widget _connectionCard(bool connected) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: RoverColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: RoverColors.cardBorder)),
        child: Row(children: [
          Icon(connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled, color: connected ? RoverColors.radarGreen : RoverColors.textMuted),
          const SizedBox(width: 10),
          Expanded(child: Text(connected ? 'Bluetooth telemetry is connected.' : 'Connect the rover in Settings.', style: const TextStyle(color: Colors.white))),
        ]),
      );

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

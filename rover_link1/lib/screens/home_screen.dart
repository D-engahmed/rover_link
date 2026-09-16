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

  const HomeScreen({super.key, this.onNavTap, required this.telemetryService, required this.bluetoothService});

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
    final angleValue = value.radarAngleDeg ?? value.targetAngleDeg;
    final distance = value.ultrasonicDistanceCm ?? value.frontDistanceCm;
    if (!mounted) return;
    setState(() {
      _telemetry = value;
      if (angleValue != null && distance != null && distance > 0) {
        final angle = angleValue.round().clamp(0, 180).toInt();
        _scan[angle] = RadarDetection(
          id: 'home-$angle',
          name: 'ULTRASONIC',
          distance: distance / 100.0,
          bearing: angle.toDouble(),
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
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _welcome(connected),
                    const SizedBox(height: 16),
                    _liveStatus(connected),
                    const SizedBox(height: 14),
                    _radarCard(),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _metric(Icons.straighten_rounded, 'DISTANCE', distance == null ? '--' : '${distance.toStringAsFixed(0)} cm')),
                      const SizedBox(width: 10),
                      Expanded(child: _metric(Icons.explore_rounded, 'ANGLE', angle == null ? '--' : '${angle.toStringAsFixed(0)}°')),
                      const SizedBox(width: 10),
                      Expanded(child: _metric(Icons.tune_rounded, 'MODE', _telemetry?.mode ?? _selectedMode)),
                    ]),
                    const SizedBox(height: 16),
                    _modeSelector(),
                    const SizedBox(height: 14),
                    _connectionCard(connected),
                    const SizedBox(height: 14),
                    _safetyCard(),
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
    padding: const EdgeInsets.fromLTRB(20, 15, 20, 13),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: RoverColors.cardBorder))),
    child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: RoverColors.cardHighlight, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.smart_toy_rounded, color: RoverColors.radarGreen, size: 21)),
      const SizedBox(width: 11),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ROVER LINK', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
        Text('COMMAND CENTER', style: TextStyle(color: RoverColors.textMuted, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      ])),
      _statusPill(connected),
    ]),
  );

  Widget _welcome(bool connected) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [RoverColors.cardHighlight, RoverColors.cardBackground], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: RoverColors.cardBorder),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Rover Command Center', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(connected ? 'Your rover is connected. Live telemetry is available.' : 'Connect your rover to unlock live telemetry and control.', style: const TextStyle(color: RoverColors.textSecondary, fontSize: 12, height: 1.35)),
      ])),
      const SizedBox(width: 12),
      Container(width: 52, height: 52, decoration: BoxDecoration(color: RoverColors.radarGreen.withValues(alpha: .10), shape: BoxShape.circle, border: Border.all(color: RoverColors.radarGreen.withValues(alpha: .28))), child: const Icon(Icons.radar_rounded, color: RoverColors.radarGreen, size: 27)),
    ]),
  );

  Widget _liveStatus(bool connected) => Row(children: [
    Expanded(child: _statusTile(Icons.bluetooth_connected, 'LINK', connected ? 'CONNECTED' : 'OFFLINE', connected ? RoverColors.radarGreen : RoverColors.textMuted)),
    const SizedBox(width: 10),
    Expanded(child: _statusTile(Icons.sensors_rounded, 'SENSOR', _telemetry == null ? 'WAITING' : 'LIVE', _telemetry == null ? RoverColors.textMuted : RoverColors.targetCyan)),
    const SizedBox(width: 10),
    Expanded(child: _statusTile(Icons.memory_rounded, 'CONTROL', 'STM32', RoverColors.textSecondary)),
  ]);

  Widget _statusTile(IconData icon, String label, String value, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: RoverColors.cardBackground, borderRadius: BorderRadius.circular(15), border: Border.all(color: RoverColors.cardBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 17, color: color), const SizedBox(height: 8), Text(label, style: const TextStyle(color: RoverColors.textMuted, fontSize: 8, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(value, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900))],
  );

  Widget _radarCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
    decoration: BoxDecoration(color: RoverColors.cardBackground, borderRadius: BorderRadius.circular(20), border: Border.all(color: RoverColors.cardBorder)),
    child: Column(children: [
      Row(children: [
        const Icon(Icons.radar_rounded, color: RoverColors.radarGreen, size: 18),
        const SizedBox(width: 8),
        const Expanded(child: Text('LIVE PERCEPTION', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1))),
        Text('${_scan.length} POINTS', style: const TextStyle(color: RoverColors.textMuted, fontSize: 8, fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 8),
      SizedBox(height: 270, child: RadarScope(detections: _scan.values.toList(), maxDistance: 8)),
    ]),
  );

  Widget _metric(IconData icon, String label, String value) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: RoverColors.cardBackground, borderRadius: BorderRadius.circular(15), border: Border.all(color: RoverColors.cardBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 15, color: RoverColors.targetCyan), const SizedBox(height: 7), Text(label, style: const TextStyle(color: RoverColors.textMuted, fontSize: 8, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900))],
  );

  Widget _modeSelector() => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: RoverColors.cardBackground, borderRadius: BorderRadius.circular(18), border: Border.all(color: RoverColors.cardBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('CONTROL MODE', style: TextStyle(color: RoverColors.textMuted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.3)),
      const SizedBox(height: 11),
      Wrap(spacing: 7, runSpacing: 7, children: ['MANUAL', 'ASSISTED', 'FOLLOW ME', 'AUTONOMOUS'].map((mode) => ChoiceChip(label: Text(mode, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)), selected: _selectedMode == mode, onSelected: (_) => setState(() => _selectedMode = mode), selectedColor: RoverColors.radarGreen.withValues(alpha: .18), backgroundColor: RoverColors.backgroundSecondary, side: const BorderSide(color: RoverColors.cardBorder))).toList()),
    ]),
  );

  Widget _connectionCard(bool connected) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: RoverColors.cardBackground, borderRadius: BorderRadius.circular(18), border: Border.all(color: connected ? RoverColors.radarGreen.withValues(alpha: .22) : RoverColors.cardBorder)),
    child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: (connected ? RoverColors.radarGreen : RoverColors.textMuted).withValues(alpha: .10), borderRadius: BorderRadius.circular(12)), child: Icon(connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled, color: connected ? RoverColors.radarGreen : RoverColors.textMuted)),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(connected ? 'Rover link active' : 'Rover not connected', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(connected ? 'Bluetooth telemetry is flowing.' : 'Open Settings to connect the rover.', style: const TextStyle(color: RoverColors.textMuted, fontSize: 10))])),
    ]),
  );

  Widget _safetyCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: RoverColors.obstacleRed.withValues(alpha: .06), borderRadius: BorderRadius.circular(16), border: Border.all(color: RoverColors.obstacleRed.withValues(alpha: .22))),
    child: const Row(children: [Icon(Icons.shield_outlined, color: RoverColors.obstacleRed, size: 20), SizedBox(width: 10), Expanded(child: Text('Safety layer: autonomous movement should always be bounded by obstacle checks and a hardware emergency stop.', style: TextStyle(color: RoverColors.textSecondary, fontSize: 10, height: 1.35)))]),
  );

  Widget _statusPill(bool connected) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: (connected ? RoverColors.radarGreen : RoverColors.textMuted).withValues(alpha: .10), borderRadius: BorderRadius.circular(20), border: Border.all(color: (connected ? RoverColors.radarGreen : RoverColors.textMuted).withValues(alpha: .22))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.circle, size: 7, color: connected ? RoverColors.radarGreen : RoverColors.textMuted), const SizedBox(width: 6), Text(connected ? 'ONLINE' : 'OFFLINE', style: TextStyle(color: connected ? RoverColors.radarGreen : RoverColors.textMuted, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: .8))]),
  );

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../models/radar_detection.dart';
import '../models/rover_telemetry.dart';
import '../services/rover_telemetry_service.dart';
import '../theme/rover_colors.dart';
import '../widgets/detection_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/radar_scope.dart';
import '../widgets/rover_bottom_nav.dart';

class RadarScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTap;
  final RoverTelemetryService telemetryService;

  const RadarScreen({
    super.key,
    this.onNavTap,
    required this.telemetryService,
  });

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  StreamSubscription<RoverTelemetry>? _subscription;
  final Map<int, RadarDetection> _scan = {};
  RoverTelemetry? _latest;
  DateTime? _lastPacket;

  @override
  void initState() {
    super.initState();
    _subscription = widget.telemetryService.telemetry.listen(_onTelemetry);
  }

  void _onTelemetry(RoverTelemetry telemetry) {
    if (!mounted) return;

    final angle = telemetry.radarAngleDeg ?? telemetry.targetAngleDeg;
    final distance = telemetry.ultrasonicDistanceCm ?? telemetry.frontDistanceCm;

    setState(() {
      _latest = telemetry;
      _lastPacket = DateTime.now();

      if (angle != null && distance != null && distance > 0) {
        final normalizedAngle = angle.round().clamp(0, 180);
        _scan[normalizedAngle] = RadarDetection(
          id: 'ultrasonic-$normalizedAngle',
          name: 'ULTRASONIC',
          distance: distance / 100.0,
          bearing: normalizedAngle.toDouble(),
          type: DetectionType.obstacle,
          color: distance <= 40
              ? RoverColors.obstacleRed
              : RoverColors.obstacleAmber,
        );
      }
    });
  }

  List<RadarDetection> get _detections => _scan.values.toList()
    ..sort((a, b) => a.distance.compareTo(b.distance));

  bool get _live => _lastPacket != null &&
      DateTime.now().difference(_lastPacket!).inSeconds < 2;

  @override
  Widget build(BuildContext context) {
    final detections = _detections;
    final nearest = detections.isEmpty ? null : detections.first;
    final currentDistance = _latest?.ultrasonicDistanceCm ??
        _latest?.frontDistanceCm;
    final currentAngle = _latest?.radarAngleDeg ?? _latest?.targetAngleDeg;

    return Scaffold(
      backgroundColor: RoverColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RadarScope(
                      detections: detections,
                      maxDistance: 8.0,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            title: 'NEAREST OBSTACLE',
                            value: nearest?.distance.toStringAsFixed(2) ?? '--',
                            unit: 'm',
                            icon: Icons.warning_amber_rounded,
                            accentColor: RoverColors.obstacleRed,
                            subtext: nearest == null
                                ? 'Waiting for sensor'
                                : '@ ${nearest.bearing.toStringAsFixed(0)}°',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCard(
                            title: 'SCAN POINTS',
                            value: '${detections.length}',
                            icon: Icons.radar_rounded,
                            accentColor: RoverColors.radarGreen,
                            subtext: 'Live ultrasonic samples',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildLiveTelemetryCard(currentDistance, currentAngle),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'LIVE DETECTIONS',
                          style: TextStyle(
                            color: RoverColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          _live ? 'LIVE' : 'NO LIVE DATA',
                          style: TextStyle(
                            color: _live
                                ? RoverColors.radarGreen
                                : RoverColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (detections.isEmpty)
                      _buildEmptyState()
                    else
                      ...detections.map((d) => DetectionCard(detection: d)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: RoverBottomNav(
        currentIndex: 2,
        onTap: widget.onNavTap,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: RoverColors.background,
        border: Border(bottom: BorderSide(color: RoverColors.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LIVE RADAR',
                style: TextStyle(
                  color: RoverColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'HC-SR04 TELEMETRY',
                style: TextStyle(
                  color: RoverColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: RoverColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: RoverColors.cardBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sensors_rounded,
                  size: 14,
                  color: _live ? RoverColors.radarGreen : RoverColors.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  _live ? 'LIVE' : 'WAITING',
                  style: TextStyle(
                    color: _live ? RoverColors.radarGreen : RoverColors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTelemetryCard(double? distance, double? angle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RoverColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RoverColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(child: _metric('DISTANCE', distance == null ? '--' : '${distance.toStringAsFixed(1)} cm')),
          Expanded(child: _metric('SERVO ANGLE', angle == null ? '--' : '${angle.toStringAsFixed(0)}°')),
          Expanded(child: _metric('MODE', _latest?.mode ?? '--')),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: RoverColors.textMuted, fontSize: 9)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: RoverColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: RoverColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RoverColors.cardBorder),
      ),
      child: const Column(
        children: [
          Icon(Icons.sensors_off_rounded, color: RoverColors.textMuted, size: 32),
          SizedBox(height: 10),
          Text('No live ultrasonic telemetry yet', style: TextStyle(color: RoverColors.textPrimary, fontWeight: FontWeight.w700)),
          SizedBox(height: 5),
          Text('Connect the rover and wait for STM32 telemetry.', textAlign: TextAlign.center, style: TextStyle(color: RoverColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

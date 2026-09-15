import 'package:flutter/material.dart';
import '../models/radar_detection.dart';
import '../theme/rover_colors.dart';
import '../widgets/detection_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/radar_scope.dart';
import '../widgets/rover_bottom_nav.dart';

class RadarScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTap;

  const RadarScreen({
    super.key,
    this.onNavTap,
  });

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  int _selectedNavIndex = 2; // Radar is active tab

  // Mock data as requested
  final List<RadarDetection> _detections = RadarDetection.defaultDetections;

  @override
  Widget build(BuildContext context) {
    // Nearest obstacle calculation
    final obstacles = _detections.where((d) => d.type == DetectionType.obstacle);
    final nearestObstacle = obstacles.isNotEmpty
        ? obstacles.reduce((a, b) => a.distance < b.distance ? a : b)
        : null;

    return Scaffold(
      backgroundColor: RoverColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Title Header
            _buildHeader(),

            // Main Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Radar Scope Widget
                    const SizedBox(height: 4),
                    RadarScope(
                      detections: _detections,
                      maxDistance: 8.0,
                    ),
                    const SizedBox(height: 18),

                    // Metrics Cards Row: "NEAREST OBSTACLE" & "TRACKED OBJECTS"
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            title: 'NEAREST OBSTACLE',
                            value: nearestObstacle != null
                                ? nearestObstacle.distance.toStringAsFixed(2)
                                : '2.10',
                            unit: 'm',
                            icon: Icons.warning_amber_rounded,
                            accentColor: RoverColors.obstacleRed,
                            subtext: nearestObstacle != null
                                ? '@ ${nearestObstacle.bearing.toStringAsFixed(0)}° Bearing'
                                : '@ 140° Bearing',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCard(
                            title: 'TRACKED OBJECTS',
                            value: '${_detections.length}',
                            icon: Icons.radar_rounded,
                            accentColor: RoverColors.radarGreen,
                            subtext: 'Active in 8m range',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // "DETECTIONS" Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'DETECTIONS',
                              style: TextStyle(
                                color: RoverColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: RoverColors.cardBackground,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: RoverColors.cardBorder,
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                '${_detections.length}',
                                style: const TextStyle(
                                  color: RoverColors.radarGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: RoverColors.radarGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 12,
                                color: RoverColors.radarGreen,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'REAL-TIME',
                                style: TextStyle(
                                  color: RoverColors.radarGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Detection List Items
                    ..._detections.map((detection) => DetectionCard(detection: detection)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: RoverBottomNav(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
          widget.onNavTap?.call(index);
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: RoverColors.background,
        border: Border(
          bottom: BorderSide(
            color: RoverColors.cardBorder,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // "LIVE RADAR" Title & Subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: RoverColors.radarGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: RoverColors.radarGreen.withValues(alpha: 0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'LIVE RADAR',
                    style: TextStyle(
                      color: RoverColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Padding(
                padding: EdgeInsets.only(left: 17),
                child: Text(
                  'AUTONOMOUS ROVER SYSTEM',
                  style: TextStyle(
                    color: RoverColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: RoverColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: RoverColors.cardBorder,
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sensors_rounded,
                  size: 14,
                  color: RoverColors.radarGreen,
                ),
                const SizedBox(width: 5),
                const Text(
                  '360° ACTIVE',
                  style: TextStyle(
                    color: RoverColors.radarGreen,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

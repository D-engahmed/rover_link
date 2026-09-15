import 'package:flutter/material.dart';
import '../theme/rover_colors.dart';

enum DetectionType {
  target,
  obstacle,
}

class RadarDetection {
  final String id;
  final String name;
  final double distance; // In meters
  final double bearing; // In degrees (0 - 360)
  final DetectionType type;
  final Color color;

  const RadarDetection({
    required this.id,
    required this.name,
    required this.distance,
    required this.bearing,
    required this.type,
    required this.color,
  });

  bool get isTarget => type == DetectionType.target;

  /// Default mock detections matching user requirements:
  /// - Target — YOU: 6.16 m @ 45°
  /// - Obstacle 1: 2.10 m @ 140°
  /// - Obstacle 2: 3.40 m @ 320°
  static List<RadarDetection> get defaultDetections => const [
        RadarDetection(
          id: 'target-you',
          name: 'Target — YOU',
          distance: 6.16,
          bearing: 45,
          type: DetectionType.target,
          color: RoverColors.targetCyan,
        ),
        RadarDetection(
          id: 'obstacle-1',
          name: 'Obstacle 1',
          distance: 2.10,
          bearing: 140,
          type: DetectionType.obstacle,
          color: RoverColors.obstacleRed,
        ),
        RadarDetection(
          id: 'obstacle-2',
          name: 'Obstacle 2',
          distance: 3.40,
          bearing: 320,
          type: DetectionType.obstacle,
          color: RoverColors.obstacleAmber,
        ),
      ];
}

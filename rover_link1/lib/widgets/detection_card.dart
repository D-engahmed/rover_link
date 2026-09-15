import 'package:flutter/material.dart';
import '../models/radar_detection.dart';
import '../theme/rover_colors.dart';

class DetectionCard extends StatelessWidget {
  final RadarDetection detection;

  const DetectionCard({
    super.key,
    required this.detection,
  });

  String _getCardinalDirection(double degrees) {
    if (degrees >= 337.5 || degrees < 22.5) return 'N';
    if (degrees >= 22.5 && degrees < 67.5) return 'NE';
    if (degrees >= 67.5 && degrees < 112.5) return 'E';
    if (degrees >= 112.5 && degrees < 157.5) return 'SE';
    if (degrees >= 157.5 && degrees < 202.5) return 'S';
    if (degrees >= 202.5 && degrees < 247.5) return 'SW';
    if (degrees >= 247.5 && degrees < 292.5) return 'W';
    return 'NW';
  }

  @override
  Widget build(BuildContext context) {
    final direction = _getCardinalDirection(detection.bearing);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: RoverColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: RoverColors.cardBorder,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // Color indicator dot / badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: detection.color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: detection.color.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                detection.isTarget ? Icons.my_location_rounded : Icons.warning_amber_rounded,
                size: 18,
                color: detection.color,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Label and bearing direction
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detection.name,
                  style: const TextStyle(
                    color: RoverColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: RoverColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: RoverColors.cardBorder,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '$direction • ${detection.bearing.toStringAsFixed(0)}°',
                        style: const TextStyle(
                          color: RoverColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Distance Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: detection.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: detection.color.withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
            child: Text(
              '${detection.distance.toStringAsFixed(2)} m',
              style: TextStyle(
                color: detection.color,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

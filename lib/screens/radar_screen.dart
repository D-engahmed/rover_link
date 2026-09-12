import 'package:flutter/material.dart';
import '../models/rover_state.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_tile.dart';
import '../widgets/radar_view.dart';

class RadarScreen extends StatelessWidget {
  const RadarScreen({super.key, required this.state});

  final RoverState state;

  @override
  Widget build(BuildContext context) {
    final nearest = state.obstacles.isEmpty
        ? null
        : state.obstacles.reduce((a, b) => a.distanceM < b.distanceM ? a : b);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          SectionCard(
            title: 'Live Radar',
            child: AspectRatio(
              aspectRatio: 1,
              child: RadarView(
                targetBearingDeg: state.targetBearingDeg,
                targetDistanceM: state.targetDistanceM,
                obstacles: state.obstacles,
                maxRangeM: 6,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  label: 'Nearest obstacle',
                  value: nearest == null ? '—' : '${nearest.distanceM.toStringAsFixed(2)} m',
                  valueColor: RoverColors.amber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricTile(label: 'Tracked objects', value: '${state.obstacles.length + 1}'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Detections',
            child: Column(
              children: [
                KeyValueRow(
                  label: 'Target — ${state.targetName}',
                  value:
                      '${state.targetDistanceM.toStringAsFixed(2)} m @ ${state.targetBearingDeg.toStringAsFixed(0)}°',
                  valueColor: RoverColors.cyan,
                ),
                for (int i = 0; i < state.obstacles.length; i++)
                  KeyValueRow(
                    label: 'Obstacle ${i + 1}',
                    value:
                        '${state.obstacles[i].distanceM.toStringAsFixed(2)} m @ ${state.obstacles[i].angleDeg.toStringAsFixed(0)}°',
                    valueColor: RoverColors.amber,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

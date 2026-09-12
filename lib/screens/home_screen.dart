import 'package:flutter/material.dart';
import '../models/rover_state.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_tile.dart';
import '../widgets/radar_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.state, required this.onChanged});

  final RoverState state;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _StatusHeader(state: state),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Live Environment',
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: RadarView(
                    targetBearingDeg: state.targetBearingDeg,
                    targetDistanceM: state.targetDistanceM,
                    obstacles: state.obstacles,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: MetricTile(
                        label: 'Distance',
                        value: '${state.targetDistanceM.toStringAsFixed(2)} m',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MetricTile(
                        label: 'Bearing',
                        value: '${state.targetBearingDeg >= 0 ? '+' : ''}${state.targetBearingDeg.toStringAsFixed(0)}°',
                        valueColor: RoverColors.cyan,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MetricTile(
                        label: 'Confidence',
                        value: '${state.confidencePct.toStringAsFixed(0)}%',
                        valueColor: RoverColors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Control Mode',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RoverMode.values.map((m) {
                final selected = state.mode == m;
                return ChoiceChip(
                  label: Text(m.label),
                  selected: selected,
                  onSelected: (_) {
                    state.setMode(m);
                    onChanged();
                  },
                  selectedColor: RoverColors.panel2,
                  backgroundColor: RoverColors.bg,
                  side: BorderSide(color: selected ? RoverColors.cyan : RoverColors.line),
                  labelStyle: TextStyle(
                    color: selected ? RoverColors.cyan : RoverColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Mission',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TARGET', style: const TextStyle(color: RoverColors.muted, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  state.targetName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const Divider(height: 28),
                KeyValueRow(label: 'Distance', value: '${state.targetDistanceM.toStringAsFixed(2)} m'),
                KeyValueRow(
                  label: 'Bearing',
                  value: '${state.targetBearingDeg >= 0 ? '+' : ''}${state.targetBearingDeg.toStringAsFixed(0)}°',
                  valueColor: RoverColors.cyan,
                ),
                KeyValueRow(
                  label: 'Confidence',
                  value: '${state.confidencePct.toStringAsFixed(0)}%',
                  valueColor: RoverColors.green,
                ),
                const SizedBox(height: 12),
                Text(
                  state.emergencyStop ? MissionStatus.emergency.label : state.missionStatus.label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: state.emergencyStop ? RoverColors.red : RoverColors.green,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: state.confidencePct / 100,
                    minHeight: 6,
                    backgroundColor: RoverColors.panel2,
                    color: RoverColors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (state.emergencyStop) {
                  state.clearEmergencyStop();
                } else {
                  state.triggerEmergencyStop();
                }
                onChanged();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF321217),
                foregroundColor: RoverColors.red,
                side: const BorderSide(color: Color(0xFF64232B)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(state.emergencyStop ? 'RESUME MISSION' : 'EMERGENCY STOP'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.state});

  final RoverState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SMART ROVER',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 0.5),
              ),
              const Text('STM32F401 · HC-05', style: TextStyle(color: RoverColors.muted, fontSize: 12)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: RoverColors.panel2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: RoverColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.connected ? RoverColors.green : RoverColors.red,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                state.connected ? 'ONLINE' : 'OFFLINE',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

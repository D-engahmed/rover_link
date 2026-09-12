import 'package:flutter/material.dart';
import '../models/rover_state.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_tile.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({super.key, required this.state});

  final RoverState state;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          SectionCard(
            title: 'Target Estimation',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${state.targetDistanceM.toStringAsFixed(2)} m · '
                  '${state.targetBearingDeg >= 0 ? '+' : ''}${state.targetBearingDeg.toStringAsFixed(0)}°',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const Divider(height: 24),
                KeyValueRow(
                  label: 'Localization confidence',
                  value: '${state.confidencePct.toStringAsFixed(0)}%',
                  valueColor: RoverColors.green,
                ),
                KeyValueRow(label: 'Position error', value: '${state.positionErrorM.toStringAsFixed(2)} m'),
                KeyValueRow(label: 'Distance error', value: '${state.distanceErrorM.toStringAsFixed(2)} m'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Navigation Decision',
            child: Text(
              state.aiDecision,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: RoverColors.cyan),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'System Pipeline',
            child: Column(
              children: [
                KeyValueRow(label: 'Bluetooth RSSI', value: '${state.rssiDbm} dBm'),
                KeyValueRow(label: 'Link latency', value: '${state.latencyMs} ms'),
                KeyValueRow(label: 'Phone IMU', value: 'ACTIVE', valueColor: RoverColors.green),
                KeyValueRow(label: 'Ultrasonic', value: '${state.ultrasonicCm.toStringAsFixed(0)} cm'),
                KeyValueRow(label: 'Servo angle', value: '${state.servoAngleDeg.toStringAsFixed(0)}°'),
                KeyValueRow(label: 'Motor speed', value: '${state.motorSpeedPct.toStringAsFixed(0)}%'),
                KeyValueRow(
                  label: 'Safety controller',
                  value: state.safetyClear ? 'CLEAR' : 'BLOCKED',
                  valueColor: state.safetyClear ? RoverColors.green : RoverColors.red,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: MetricTile(
                      label: 'Perception', value: 'TARGET DETECTED', valueColor: RoverColors.green)),
              const SizedBox(width: 10),
              Expanded(
                  child: MetricTile(
                      label: 'Safety',
                      value: state.safetyClear ? 'PATH CLEAR' : 'AVOID LEFT',
                      valueColor: state.safetyClear ? RoverColors.green : RoverColors.amber)),
            ],
          ),
        ],
      ),
    );
  }
}

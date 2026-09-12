import 'package:flutter/material.dart';
import '../models/rover_state.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_tile.dart';

class DriveScreen extends StatelessWidget {
  const DriveScreen({super.key, required this.state, required this.onChanged});

  final RoverState state;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final assisted = state.mode == RoverMode.assisted;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          SectionCard(
            title: assisted ? 'Assisted Drive' : 'Manual Drive',
            child: Column(
              children: [
                if (assisted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: RoverColors.panel2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            state.safetyClear ? Icons.check_circle : Icons.warning_amber,
                            color: state.safetyClear ? RoverColors.green : RoverColors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.safetyClear
                                  ? 'AI assist: path clear'
                                  : 'AI assist: obstacle detected — steering adjusted',
                              style: const TextStyle(fontSize: 12, color: RoverColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(
                  height: 240,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _padButton(Icons.keyboard_arrow_up, () => state.sendDriveCommand('forward')),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _padButton(Icons.keyboard_arrow_left, () => state.sendDriveCommand('left')),
                          const SizedBox(width: 28),
                          _padButton(Icons.stop, () => state.sendDriveCommand('stop'), filled: true),
                          const SizedBox(width: 28),
                          _padButton(Icons.keyboard_arrow_right, () => state.sendDriveCommand('right')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _padButton(Icons.keyboard_arrow_down, () => state.sendDriveCommand('backward')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Speed',
            child: Column(
              children: [
                Slider(
                  value: state.driveSpeedPct,
                  min: 0,
                  max: 100,
                  activeColor: RoverColors.cyan,
                  inactiveColor: RoverColors.panel2,
                  onChanged: (v) {
                    state.driveSpeedPct = v;
                    onChanged();
                  },
                ),
                Text('${state.driveSpeedPct.round()}%', style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  label: 'Obstacle',
                  value: state.safetyClear ? 'CLEAR' : 'BLOCKED',
                  valueColor: state.safetyClear ? RoverColors.green : RoverColors.red,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricTile(label: 'Ultrasonic', value: '${state.ultrasonicCm.toStringAsFixed(0)} cm'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _padButton(IconData icon, VoidCallback onTap, {bool filled = false}) {
    return Material(
      color: filled ? const Color(0xFF321217) : RoverColors.panel2,
      shape: const CircleBorder(side: BorderSide(color: RoverColors.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Icon(icon, color: filled ? RoverColors.red : RoverColors.text, size: 28),
        ),
      ),
    );
  }
}

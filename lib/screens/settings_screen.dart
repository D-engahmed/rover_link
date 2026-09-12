import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter/material.dart';
import '../models/rover_state.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state, required this.onChanged});

  final RoverState state;
  final VoidCallback onChanged;

  Future<void> _openDevicePicker(BuildContext context) async {
    final devices = await state.connection.pairedDevices();
    if (!context.mounted) return;
    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No paired devices found — pair the HC-05 in your phone\'s Bluetooth settings first.'),
        ),
      );
      return;
    }
    final chosen = await showModalBottomSheet<BluetoothDevice>(
      context: context,
      backgroundColor: RoverColors.panel,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Paired devices', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            for (final d in devices)
              ListTile(
                title: Text(d.name ?? 'Unknown device'),
                subtitle: Text(d.address),
                onTap: () => Navigator.pop(ctx, d),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) {
      final ok = await state.connection.connect(chosen);
      onChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Connected to ${chosen.name}' : 'Could not connect — is the HC-05 powered on?')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          SectionCard(
            title: 'Connection',
            child: _SettingsTile(
              label: 'Bluetooth / HC-05',
              value: state.connected ? 'CONNECTED' : 'DISCONNECTED',
              valueColor: state.connected ? RoverColors.green : RoverColors.muted,
              onTap: state.connected
                  ? () async {
                      await state.connection.disconnect();
                      onChanged();
                    }
                  : () => _openDevicePicker(context),
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Classic Bluetooth (SPP) only — Android. iOS can\'t open the '
              'HC-05\'s serial profile; a BLE module on the rover side would '
              'be needed to support iOS.',
              style: TextStyle(color: RoverColors.muted, fontSize: 11),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Mission Parameters',
            child: Column(
              children: [
                _SettingsTile(label: 'Follow distance', value: '1.5 m', onTap: () {}),
                _SettingsTile(label: 'Obstacle threshold', value: '30 cm', onTap: () {}),
                _SettingsTile(label: 'Target lost threshold', value: '40%', onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Hardware',
            child: Column(
              children: [
                _SettingsTile(label: 'Motor calibration', value: 'OPEN', onTap: () {}),
                _SettingsTile(label: 'Firmware version', value: 'v0.1.0', onTap: null),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.label, required this.value, this.valueColor, this.onTap});

  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: RoverColors.muted, fontSize: 14)),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? RoverColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: RoverColors.muted, size: 18),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

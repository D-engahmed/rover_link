import 'package:flutter/material.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

import '../widgets/rover_bottom_nav.dart';
import '../services/bluetooth_service.dart';

class SettingsScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTap;
  final BluetoothService bluetoothService;
  final Future<void> Function()? onConnected;

  const SettingsScreen({
    super.key,
    this.onNavTap,
    required this.bluetoothService,
    this.onConnected,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isScanning = false;
  bool isConnected = false;
  List<BtcDevice> devices = [];

  Future<void> _scanBluetoothDevices() async {
    setState(() {
      isScanning = true;
      devices = [];
    });
    try {
      final result = await widget.bluetoothService.scanDevices();
      if (!mounted) return;
      setState(() {
        devices = result;
        isScanning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bluetooth scan failed: $e')),
      );
    }
  }

  Future<void> _connectToDevice(BtcDevice device) async {
    try {
      await widget.bluetoothService.connectToDevice(device.address);
      if (!mounted) return;
      setState(() => isConnected = true);
      await widget.onConnected?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.name ?? 'Bluetooth device'}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SETTINGS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: 'CONNECTION',
                children: [
                  _buildActionRow(
                    label: 'Bluetooth / HC-05',
                    value: isScanning
                        ? 'SCANNING...'
                        : isConnected
                            ? 'CONNECTED'
                            : 'SCAN',
                    valueColor: isScanning
                        ? const Color(0xFFFFC857)
                        : const Color(0xFF69F0AE),
                    showChevron: true,
                    onTap: isScanning ? null : _scanBluetoothDevices,
                  ),
                  if (devices.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...devices.map(
                      (device) => InkWell(
                        onTap: () => _connectToDevice(device),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1117),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.bluetooth, color: Color(0xFF69F0AE), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        device.name ?? 'Unknown Device',
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        device.address,
                                        style: const TextStyle(color: Color(0xFF8A96A3), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              _buildSectionCard(
                title: 'MISSION PARAMETERS',
                children: [
                  _buildActionRow(label: 'Follow distance', value: '1.5 m', showChevron: true),
                  _buildDivider(),
                  _buildActionRow(label: 'Obstacle threshold', value: '30 cm', showChevron: true),
                  _buildDivider(),
                  _buildActionRow(label: 'Target lost threshold', value: '40%', showChevron: true),
                ],
              ),
              const SizedBox(height: 14),
              _buildSectionCard(
                title: 'BASELINE AUTONOMY',
                children: [
                  _buildActionRow(label: 'Controller', value: 'Phone / baseline_v1', showChevron: false),
                  _buildDivider(),
                  _buildActionRow(label: 'Backend required', value: 'NO', showChevron: false),
                  _buildDivider(),
                  _buildActionRow(label: 'Dataset capture', value: 'ON AFTER CONNECT', showChevron: false),
                ],
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      bottomNavigationBar: RoverBottomNav(currentIndex: 4, onTap: widget.onNavTap),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF26303B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required String label,
    required String value,
    bool showChevron = false,
    Color valueColor = const Color(0xFFB8C1CC),
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: Color(0xFFDCE3EA), fontSize: 13))),
            Text(value, style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.w800)),
            if (showChevron) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.chevron_right, color: Color(0xFF64717E), size: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => const Divider(color: Color(0xFF26303B), height: 1);
}

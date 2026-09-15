 
import 'package:flutter/material.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

import '../widgets/rover_bottom_nav.dart';
import '../services/bluetooth_service.dart';
 class SettingsScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTap;
  final BluetoothService bluetoothService;

  const SettingsScreen({
    super.key,
    this.onNavTap,
    required this.bluetoothService,
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

      setState(() {
        isScanning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bluetooth scan failed: $e'),
        ),
      );
    }
  }

  Future<void> _connectToDevice(BtcDevice device) async {
    try {
       await widget.bluetoothService.connectToDevice(device.address);
      if (!mounted) return;

setState(() {
  isConnected = true;
});

 

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connected to ${device.name ?? 'Bluetooth device'}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection failed: $e'),
        ),
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
              // PAGE TITLE
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

              // CONNECTION
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

                    onTap: isScanning
                        ? null
                        : _scanBluetoothDevices,
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
                                const Icon(
                                  Icons.bluetooth,
                                  color: Color(0xFF69F0AE),
                                  size: 20,
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      Text(
                                        device.name ??
                                            'Unknown Device',

                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),

                                      const SizedBox(height: 3),

                                      Text(
                                        device.address,

                                        style: const TextStyle(
                                          color: Color(0xFF8A96A3),
                                          fontSize: 11,
                                        ),
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

              // MISSION PARAMETERS
              _buildSectionCard(
                title: 'MISSION PARAMETERS',

                children: [
                  _buildActionRow(
                    label: 'Follow distance',
                    value: '1.5 m',
                    showChevron: true,
                  ),

                  _buildDivider(),

                  _buildActionRow(
                    label: 'Obstacle threshold',
                    value: '30 cm',
                    showChevron: true,
                  ),

                  _buildDivider(),

                  _buildActionRow(
                    label: 'Target lost threshold',
                    value: '40%',
                    showChevron: true,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // HARDWARE
              _buildSectionCard(
                title: 'HARDWARE',

                children: [
                  _buildActionRow(
                    label: 'Motor calibration',
                    value: 'OPEN',
                    showChevron: true,
                  ),

                  _buildDivider(),

                  _buildActionRow(
                    label: 'Firmware version',
                    value: 'v0.1.0',
                    showChevron: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // SETTINGS = INDEX 4
      bottomNavigationBar: RoverBottomNav(
        currentIndex: 4,
        onTap: widget.onNavTap,
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: const Color(0xFF111923),
        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: const Color(0xFF1D2A38),
          width: 1,
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              title,

              style: const TextStyle(
                color: Color(0xFF9AA7B5),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required String label,
    required String value,
    required bool showChevron,

    Color valueColor = Colors.white,

    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(8),

        child: Row(
          children: [
            Expanded(
              child: Text(
                label,

                style: const TextStyle(
                  color: Color(0xFFD1D7DE),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            Text(
              value,

              style: TextStyle(
                color: valueColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),

            if (showChevron) ...[
              const SizedBox(width: 4),

              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8A96A3),
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFF1D2A38),
    );
  }
}
 

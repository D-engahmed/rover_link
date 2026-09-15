import 'package:flutter/material.dart';

class AiScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTap;

  const AiScreen({
    super.key,
    this.onNavTap,
  });

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
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
              // Header
              const Text(
                'AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // TARGET ESTIMATION
              _buildCard(
                title: 'TARGET ESTIMATION',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '6.11 m · +43°',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildMetricRow(
                      'Localization confidence',
                      '72%',
                      valueColor: const Color(0xFF69F0AE),
                    ),
                    const SizedBox(height: 10),
                    _buildMetricRow(
                      'Position error',
                      '0.42 m',
                    ),
                    const SizedBox(height: 10),
                    _buildMetricRow(
                      'Distance error',
                      '0.31 m',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // NAVIGATION DECISION
              _buildCard(
                title: 'NAVIGATION DECISION',
                child: const Text(
                  'TURN RIGHT 18° → FORWARD',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // SYSTEM PIPELINE
              _buildCard(
                title: 'SYSTEM PIPELINE',
                child: Column(
                  children: [
                    _buildMetricRow('Bluetooth RSSI', '-60 dBm'),
                    _buildMetricRow('Link latency', '42 ms'),
                    _buildMetricRow(
                      'Phone IMU',
                      'ACTIVE',
                      valueColor: const Color(0xFF69F0AE),
                    ),
                    _buildMetricRow('Ultrasonic', '178 cm'),
                    _buildMetricRow('Servo angle', '74°'),
                    _buildMetricRow('Motor speed', '48%'),
                    _buildMetricRow(
                      'Safety controller',
                      'CLEAR',
                      valueColor: const Color(0xFF69F0AE),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Bottom status cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      title: 'PERCEPTION',
                      value: 'TARGET DETECTED',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusCard(
                      title: 'SAFETY',
                      value: 'PATH CLEAR',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111923),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1D2A38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF9AA7B5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value, {
    Color valueColor = Colors.white,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB0BAC5),
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111923),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1D2A38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF9AA7B5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF69F0AE),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
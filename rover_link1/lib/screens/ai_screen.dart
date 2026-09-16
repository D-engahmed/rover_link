import 'dart:async';

import 'package:flutter/material.dart';

import '../models/rover_telemetry.dart';
import '../services/bluetooth_service.dart';
import '../services/rover_ai_service.dart';
import '../services/rover_telemetry_service.dart';
import '../theme/rover_colors.dart';
import '../widgets/rover_bottom_nav.dart';

class AiScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTap;
  final RoverAiService aiService;
  final RoverTelemetryService telemetryService;
  final BluetoothService bluetoothService;

  const AiScreen({
    super.key,
    this.onNavTap,
    required this.aiService,
    required this.telemetryService,
    required this.bluetoothService,
  });

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  StreamSubscription<RoverTelemetry>? _telemetrySubscription;
  StreamSubscription<AiDecision>? _decisionSubscription;

  RoverTelemetry? _telemetry;
  AiDecision? _decision;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _telemetrySubscription = widget.telemetryService.telemetry.listen((value) {
      if (mounted) setState(() => _telemetry = value);
    });
    _decisionSubscription = widget.aiService.decisions.listen((value) {
      if (mounted) setState(() => _decision = value);
    });
  }

  Future<void> _toggleAi() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      if (widget.aiService.state == AiRunState.running) {
        await widget.aiService.stop();
      } else {
        if (!widget.bluetoothService.isReady) {
          throw Exception('Connect the rover from Settings first.');
        }
        await widget.aiService.start();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiRunning = widget.aiService.state == AiRunState.running;
    final front = _telemetry?.frontDistanceCm;
    final targetDistance = _telemetry?.targetDistanceCm;
    final targetAngle = _telemetry?.targetAngleDeg;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('AI AUTOPILOT', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  _statusChip(aiRunning ? 'RUNNING' : 'STOPPED', aiRunning),
                ],
              ),
              const SizedBox(height: 14),
              _card(
                title: 'ON-DEVICE NAVIGATION',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            aiRunning ? 'AI is controlling the rover locally.' : 'AI is ready. Connect the rover, then start autopilot.',
                            style: const TextStyle(color: Color(0xFFB0BAC5), fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _busy ? null : _toggleAi,
                          child: Text(aiRunning ? 'STOP' : 'START AI'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Model: rover_navigation_policy_v0.1 (embedded)', style: TextStyle(color: Color(0xFF69F0AE), fontSize: 11)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _card(
                title: 'LIVE SENSOR STATE',
                child: Column(
                  children: [
                    _row('Front distance', front == null ? '--' : '${front.toStringAsFixed(1)} cm'),
                    _row('Target distance', targetDistance == null ? '--' : '${targetDistance.toStringAsFixed(1)} cm'),
                    _row('Target / radar angle', targetAngle == null ? '--' : '${targetAngle.toStringAsFixed(0)}°'),
                    _row('Bluetooth', widget.bluetoothService.isReady ? 'READY' : 'DISCONNECTED', good: widget.bluetoothService.isReady),
                    _row('Rover mode', _telemetry?.mode ?? '--'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _card(
                title: 'AI DECISION',
                child: Column(
                  children: [
                    Text(
                      _decision?.label ?? 'WAITING FOR TELEMETRY',
                      style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _row('Confidence', _decision == null ? '--' : '${(_decision!.confidence * 100).toStringAsFixed(0)}%'),
                    _row('Left score', _decision == null ? '--' : _decision!.scoreLeft.toStringAsFixed(2)),
                    _row('Forward score', _decision == null ? '--' : _decision!.scoreForward.toStringAsFixed(2)),
                    _row('Right score', _decision == null ? '--' : _decision!.scoreRight.toStringAsFixed(2)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _statusCard('SAFETY', front != null && front <= 18 ? 'STOP REQUIRED' : 'MONITORING', front != null && front > 18)),
                  const SizedBox(width: 12),
                  Expanded(child: _statusCard('PERCEPTION', _telemetry == null ? 'NO DATA' : 'TELEMETRY LIVE', _telemetry != null)),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: RoverBottomNav(
        currentIndex: 3,
        onTap: widget.onNavTap,
      ),
    );
  }

  Widget _statusChip(String text, bool good) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF111923),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: good ? const Color(0xFF69F0AE) : const Color(0xFF334155)),
        ),
        child: Text(text, style: TextStyle(color: good ? const Color(0xFF69F0AE) : const Color(0xFF9AA7B5), fontSize: 10, fontWeight: FontWeight.bold)),
      );

  Widget _card({required String title, required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111923),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1D2A38)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Color(0xFF9AA7B5), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
          const SizedBox(height: 12),
          child,
        ]),
      );

  Widget _row(String label, String value, {bool good = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFFB0BAC5), fontSize: 13))),
          Text(value, style: TextStyle(color: good ? const Color(0xFF69F0AE) : Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _statusCard(String title, String value, bool good) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111923),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1D2A38)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Color(0xFF9AA7B5), fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: good ? const Color(0xFF69F0AE) : const Color(0xFFFFB4AB), fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      );

  @override
  void dispose() {
    _telemetrySubscription?.cancel();
    _decisionSubscription?.cancel();
    super.dispose();
  }
}

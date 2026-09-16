import 'dart:async';

import 'package:flutter/material.dart';

import '../models/command_trace.dart';
import '../models/rover_telemetry.dart';
import '../services/bluetooth_service.dart';
import '../services/rover_ai_service.dart';
import '../services/rover_command_service.dart';
import '../services/rover_telemetry_service.dart';
import '../theme/rover_colors.dart';
import '../widgets/rover_bottom_nav.dart';

class AiScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTap;
  final RoverAiService aiService;
  final RoverCommandService commandService;
  final RoverTelemetryService telemetryService;
  final BluetoothService bluetoothService;

  const AiScreen({super.key, this.onNavTap, required this.aiService, required this.commandService, required this.telemetryService, required this.bluetoothService});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  StreamSubscription<RoverTelemetry>? _telemetrySubscription;
  StreamSubscription<AiDecision>? _decisionSubscription;
  StreamSubscription<CommandTrace>? _traceSubscription;
  RoverTelemetry? _telemetry;
  AiDecision? _decision;
  final List<CommandTrace> _traces = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _telemetrySubscription = widget.telemetryService.telemetry.listen((value) { if (mounted) setState(() => _telemetry = value); });
    _decisionSubscription = widget.aiService.decisions.listen((value) { if (mounted) setState(() => _decision = value); });
    _traceSubscription = widget.commandService.traces.listen((value) {
      if (!mounted) return;
      setState(() { _traces.insert(0, value); if (_traces.length > 80) _traces.removeLast(); });
    });
  }

  Future<void> _toggleAi() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (widget.aiService.state == AiRunState.running) {
        await widget.aiService.stop();
      } else {
        if (!widget.bluetoothService.isReady) throw Exception('Connect the rover from Settings first.');
        await widget.aiService.start();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  CommandTrace? _latestAiTrace(CommandStage stage) {
    for (final trace in _traces) {
      if (trace.source == CommandSource.ai && trace.stage == stage) return trace;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final aiRunning = widget.aiService.state == AiRunState.running;
    final front = _telemetry?.frontDistanceCm;
    final aiSent = _latestAiTrace(CommandStage.sent);
    final aiFailed = _latestAiTrace(CommandStage.failed);
    final aiBlocked = _latestAiTrace(CommandStage.blocked);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('AI AUTOPILOT', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)), _statusChip(aiRunning ? 'RUNNING' : 'STOPPED', aiRunning)]),
        const SizedBox(height: 14),
        _card(title: 'ON-DEVICE NAVIGATION', child: Column(children: [
          Row(children: [Expanded(child: Text(aiRunning ? 'Inference and command generation are running on the phone.' : 'AI is idle. Connect the rover, then start autopilot.', style: const TextStyle(color: Color(0xFFB0BAC5), fontSize: 14))), const SizedBox(width: 12), ElevatedButton(onPressed: _busy ? null : _toggleAi, child: Text(aiRunning ? 'STOP' : 'START AI'))]),
          const SizedBox(height: 12), const Align(alignment: Alignment.centerLeft, child: Text('Runtime: Flutter Android app • Model: rover_navigation_policy_v0.1 baseline', style: TextStyle(color: Color(0xFF69F0AE), fontSize: 11))),
        ])),
        const SizedBox(height: 14),
        _card(title: 'CURRENT AI OUTPUT', child: Column(children: [
          _row('Decision', _decision?.label ?? '--', good: _decision != null),
          _row('Confidence', _decision == null ? '--' : '${(_decision!.confidence * 100).toStringAsFixed(0)}%'),
          _row('Left / Forward / Right', _decision == null ? '--' : '${_decision!.scoreLeft.toStringAsFixed(2)} / ${_decision!.scoreForward.toStringAsFixed(2)} / ${_decision!.scoreRight.toStringAsFixed(2)}'),
          _row('Sensor input', front == null ? 'WAITING FOR TELEMETRY' : '${front.toStringAsFixed(1)} cm front'),
        ])),
        const SizedBox(height: 14),
        _card(title: 'AI → BLUETOOTH → STM32', child: Column(children: [
          _row('AI output', _decision?.label ?? '--', good: _decision != null),
          _row('Last AI TX', aiSent?.wireCommand.isEmpty == false ? '${aiSent!.wireCommand}\\r\\n' : '--', good: aiSent != null),
          _row('TX status', aiSent != null ? 'BLUETOOTH WRITE SUCCEEDED' : aiFailed != null ? 'BLUETOOTH WRITE FAILED' : aiBlocked != null ? 'BLOCKED' : 'NO AI COMMAND'),
          _row('TX latency', aiSent?.latencyMs == null ? '--' : '${aiSent!.latencyMs} ms'),
          _row('STM32 execution ACK', 'NOT IMPLEMENTED', good: false),
        ])),
        const SizedBox(height: 14),
        _card(title: 'LIVE SENSOR STATE', child: Column(children: [
          _row('Front distance', front == null ? '--' : '${front.toStringAsFixed(1)} cm'),
          _row('Target distance', _telemetry?.targetDistanceCm == null ? '--' : '${_telemetry!.targetDistanceCm!.toStringAsFixed(1)} cm'),
          _row('Target / radar angle', _telemetry?.targetAngleDeg == null ? '--' : '${_telemetry!.targetAngleDeg!.toStringAsFixed(0)}°'),
          _row('Rover mode', _telemetry?.mode ?? '--'),
          _row('Bluetooth', widget.bluetoothService.isReady ? 'READY' : 'DISCONNECTED', good: widget.bluetoothService.isReady),
        ])),
        const SizedBox(height: 14),
        _card(title: 'COMMAND TRACE', child: _traces.isEmpty ? const Text('No command events yet.', style: TextStyle(color: Color(0xFF9AA7B5))) : Column(children: _traces.take(20).map(_traceRow).toList())),
        const SizedBox(height: 14),
        Row(children: [Expanded(child: _statusCard('SAFETY', front != null && front <= 18 ? 'STOP REQUIRED' : 'MONITORING', front == null || front > 18)), const SizedBox(width: 12), Expanded(child: _statusCard('PERCEPTION', _telemetry == null ? 'NO DATA' : 'TELEMETRY LIVE', _telemetry != null))]),
      ]))),
      bottomNavigationBar: RoverBottomNav(currentIndex: 3, onTap: widget.onNavTap),
    );
  }

  Widget _traceRow(CommandTrace t) => Container(margin: const EdgeInsets.only(bottom: 7), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF0B121A), borderRadius: BorderRadius.circular(9), border: Border.all(color: const Color(0xFF1D2A38))), child: Row(children: [SizedBox(width: 56, child: Text(t.sourceLabel, style: TextStyle(color: t.source == CommandSource.ai ? RoverColors.targetCyan : Colors.white, fontSize: 8, fontWeight: FontWeight.w900))), Expanded(child: Text('${t.action}  →  ${t.wireCommand.isEmpty ? '--' : t.wireCommand}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))), Text(t.stageLabel, style: TextStyle(color: t.stage == CommandStage.sent ? RoverColors.radarGreen : t.stage == CommandStage.failed || t.stage == CommandStage.blocked ? RoverColors.obstacleRed : RoverColors.textMuted, fontSize: 8, fontWeight: FontWeight.w900))]));

  Widget _statusChip(String text, bool good) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF111923), borderRadius: BorderRadius.circular(20), border: Border.all(color: good ? const Color(0xFF69F0AE) : const Color(0xFF334155))), child: Text(text, style: TextStyle(color: good ? const Color(0xFF69F0AE) : const Color(0xFF9AA7B5), fontSize: 10, fontWeight: FontWeight.bold)));
  Widget _card({required String title, required Widget child}) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF111923), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1D2A38))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Color(0xFF9AA7B5), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)), const SizedBox(height: 12), child]));
  Widget _row(String label, String value, {bool good = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: Color(0xFFB0BAC5), fontSize: 13))), Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: good ? const Color(0xFF69F0AE) : Colors.white, fontSize: 13, fontWeight: FontWeight.w700)))]));
  Widget _statusCard(String title, String value, bool good) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF111923), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1D2A38))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Color(0xFF9AA7B5), fontSize: 11, fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text(value, style: TextStyle(color: good ? const Color(0xFF69F0AE) : const Color(0xFFFFB4AB), fontSize: 12, fontWeight: FontWeight.bold))]));

  @override
  void dispose() { _telemetrySubscription?.cancel(); _decisionSubscription?.cancel(); _traceSubscription?.cancel(); super.dispose(); }
}

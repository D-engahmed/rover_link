import 'dart:async';
import 'package:flutter/material.dart';
import '../models/command_trace.dart';
import '../services/rover_command_service.dart';
import '../theme/rover_colors.dart';
import '../widgets/rover_bottom_nav.dart';

class CommandMonitorScreen extends StatefulWidget {
  final RoverCommandService commandService;
  final ValueChanged<int>? onNavTap;
  const CommandMonitorScreen({super.key, required this.commandService, this.onNavTap});
  @override State<CommandMonitorScreen> createState() => _CommandMonitorScreenState();
}

class _CommandMonitorScreenState extends State<CommandMonitorScreen> {
  StreamSubscription<CommandTrace>? _subscription;
  final List<CommandTrace> _items = [];
  CommandSource? _filter;

  @override
  void initState() {
    super.initState();
    _subscription = widget.commandService.traces.listen((trace) {
      if (!mounted) return;
      setState(() { _items.insert(0, trace); if (_items.length > 200) _items.removeLast(); });
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _filter == null ? _items : _items.where((e) => e.source == _filter).toList();
    return Scaffold(
      backgroundColor: RoverColors.background,
      appBar: AppBar(title: const Text('COMMAND MONITOR', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1)), actions: [IconButton(onPressed: () => setState(_items.clear), icon: const Icon(Icons.delete_sweep_rounded))]),
      body: Column(children: [
        SizedBox(height: 54, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), children: [
          _chip('ALL', null), _chip('AI', CommandSource.ai), _chip('HUMAN', CommandSource.human), _chip('SAFETY', CommandSource.safety), _chip('SYSTEM', CommandSource.system),
        ])),
        Expanded(child: items.isEmpty ? const Center(child: Text('No command events yet.', style: TextStyle(color: RoverColors.textMuted))) : ListView.separated(padding: const EdgeInsets.fromLTRB(12, 4, 12, 24), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 7), itemBuilder: (_, i) => _event(items[i]))),
      ]),
      bottomNavigationBar: RoverBottomNav(currentIndex: 3, onTap: widget.onNavTap),
    );
  }

  Widget _chip(String label, CommandSource? source) => Padding(padding: const EdgeInsets.only(right: 7), child: ChoiceChip(label: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)), selected: _filter == source, onSelected: (_) => setState(() => _filter = source), selectedColor: RoverColors.radarGreen.withValues(alpha: .18), backgroundColor: RoverColors.cardBackground, side: const BorderSide(color: RoverColors.cardBorder)));

  Widget _event(CommandTrace t) {
    final color = t.stage == CommandStage.sent ? RoverColors.radarGreen : t.stage == CommandStage.failed || t.stage == CommandStage.blocked ? RoverColors.obstacleRed : t.source == CommandSource.ai ? RoverColors.targetCyan : RoverColors.textSecondary;
    final time = '${t.timestamp.hour.toString().padLeft(2, '0')}:${t.timestamp.minute.toString().padLeft(2, '0')}:${t.timestamp.second.toString().padLeft(2, '0')}.${t.timestamp.millisecond.toString().padLeft(3, '0')}';
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: RoverColors.cardBackground, borderRadius: BorderRadius.circular(13), border: Border.all(color: RoverColors.cardBorder)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text(time, style: const TextStyle(color: RoverColors.textMuted, fontSize: 8, fontFamily: 'monospace')), const Spacer(), Text(t.sourceLabel, style: TextStyle(color: t.source == CommandSource.ai ? RoverColors.targetCyan : Colors.white, fontSize: 8, fontWeight: FontWeight.w900)), const SizedBox(width: 8), Text(t.stageLabel, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900))]), const SizedBox(height: 8), Row(children: [Expanded(child: Text(t.action, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))), Text(t.wireCommand.isEmpty ? '--' : '${t.wireCommand}\\r\\n', style: const TextStyle(color: RoverColors.targetCyan, fontSize: 11, fontFamily: 'monospace'))]), if (t.latencyMs != null || t.reason != null) ...[const SizedBox(height: 5), Text(t.latencyMs != null ? 'TX latency: ${t.latencyMs} ms' : 'Error: ${t.reason}', style: const TextStyle(color: RoverColors.textMuted, fontSize: 9))]]));
  }

  @override void dispose() { _subscription?.cancel(); super.dispose(); }
}

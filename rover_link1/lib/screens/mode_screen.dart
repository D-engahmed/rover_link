import 'dart:async';

import 'package:flutter/material.dart';

import '../services/bluetooth_service.dart';
import '../services/rover_ai_service.dart';
import '../services/rover_command_service.dart';
import '../services/rover_telemetry_service.dart';
import '../theme/rover_colors.dart';
import '../widgets/rover_bottom_nav.dart';

enum RoverMode { manual, assisted, autonomous, followMe }

class ModeScreen extends StatefulWidget {
  final RoverMode mode;
  final ValueChanged<int>? onNavTap;
  final RoverCommandService commandService;
  final RoverAiService aiService;
  final RoverTelemetryService telemetryService;
  final BluetoothService bluetoothService;

  const ModeScreen({
    super.key,
    required this.mode,
    required this.commandService,
    required this.aiService,
    required this.telemetryService,
    required this.bluetoothService,
    this.onNavTap,
  });

  @override
  State<ModeScreen> createState() => _ModeScreenState();
}

class _ModeScreenState extends State<ModeScreen> {
  StreamSubscription<AiDecision>? _decisionSubscription;
  AiDecision? _decision;
  bool _active = false;

  String get title => switch (widget.mode) {
        RoverMode.manual => 'Manual Drive',
        RoverMode.assisted => 'Assisted Drive',
        RoverMode.autonomous => 'Autonomous',
        RoverMode.followMe => 'Follow Me',
      };

  String get subtitle => switch (widget.mode) {
        RoverMode.manual => 'You control the rover directly.',
        RoverMode.assisted => 'You drive. The app adds collision protection.',
        RoverMode.autonomous => 'The phone navigation policy drives the rover.',
        RoverMode.followMe => 'The phone tracks a target and navigates toward it.',
      };

  IconData get icon => switch (widget.mode) {
        RoverMode.manual => Icons.gamepad_rounded,
        RoverMode.assisted => Icons.shield_rounded,
        RoverMode.autonomous => Icons.smart_toy_rounded,
        RoverMode.followMe => Icons.person_pin_circle_rounded,
      };

  Color get accent => switch (widget.mode) {
        RoverMode.manual => RoverColors.targetCyan,
        RoverMode.assisted => RoverColors.obstacleAmber,
        RoverMode.autonomous => RoverColors.radarGreen,
        RoverMode.followMe => const Color(0xFFB28CFF),
      };

  @override
  void initState() {
    super.initState();
    _decisionSubscription = widget.aiService.decisions.listen((value) {
      if (!mounted) return;
      setState(() => _decision = value);
    });
  }

  Future<void> _activate() async {
    if (!widget.bluetoothService.isReady) {
      _message('Connect the rover in Settings first.');
      return;
    }

    if (widget.mode == RoverMode.manual) {
      widget.onNavTap?.call(1);
      return;
    }

    if (widget.mode == RoverMode.autonomous) {
      try {
        await widget.aiService.start();
        if (mounted) setState(() => _active = true);
      } catch (e) {
        _message('Autonomous mode could not start: $e');
      }
      return;
    }

    if (widget.mode == RoverMode.assisted) {
      try {
        await widget.commandService.manualMode();
        if (mounted) setState(() => _active = true);
        _message('Assisted mode armed. Manual driving remains the primary control.');
      } catch (e) {
        _message('Assisted mode could not start: $e');
      }
      return;
    }

    // Follow Me is intentionally explicit: the app UI is ready, but target
    // identification is not claimed until a real target-tracking model exists.
    if (widget.mode == RoverMode.followMe) {
      if (mounted) setState(() => _active = true);
      _message('Follow Me is in target-acquisition mode. No human detector is claimed yet.');
    }
  }

  Future<void> _stop() async {
    await widget.aiService.stop();
    try {
      await widget.commandService.stop();
    } catch (_) {}
    if (mounted) setState(() => _active = false);
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connected = widget.bluetoothService.isReady;
    final aiRunning = widget.aiService.state == AiRunState.running;

    return Scaffold(
      backgroundColor: RoverColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(connected)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _hero(),
                  const SizedBox(height: 14),
                  _statusCard(connected, aiRunning),
                  const SizedBox(height: 14),
                  _logicCard(),
                  const SizedBox(height: 14),
                  if (_decision != null) _decisionCard(),
                  if (_decision != null) const SizedBox(height: 14),
                  _actionCard(),
                  const SizedBox(height: 14),
                  _safetyCard(),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: RoverBottomNav(currentIndex: 0, onTap: widget.onNavTap),
    );
  }

  Widget _header(bool connected) => Container(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: RoverColors.cardBorder)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              color: RoverColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _pill(connected ? 'ONLINE' : 'OFFLINE', connected ? RoverColors.radarGreen : RoverColors.textMuted),
          ],
        ),
      );

  Widget _hero() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent.withValues(alpha: .16), RoverColors.cardBackground],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: .30)),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: accent.withValues(alpha: .28)),
              ),
              child: Icon(icon, color: accent, size: 29),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text(subtitle, style: const TextStyle(color: RoverColors.textSecondary, fontSize: 11, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _statusCard(bool connected, bool aiRunning) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: RoverColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: RoverColors.cardBorder),
        ),
        child: Row(
          children: [
            _statusItem(Icons.bluetooth_rounded, 'LINK', connected ? 'CONNECTED' : 'OFFLINE', connected ? RoverColors.radarGreen : RoverColors.textMuted),
            const SizedBox(width: 10),
            _statusItem(Icons.memory_rounded, 'AI', aiRunning ? 'RUNNING' : 'STANDBY', aiRunning ? RoverColors.radarGreen : RoverColors.textMuted),
            const SizedBox(width: 10),
            _statusItem(Icons.sensors_rounded, 'DATA', 'LIVE STREAM', RoverColors.targetCyan),
          ],
        ),
      );

  Widget _statusItem(IconData icon, String label, String value, Color color) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(height: 7),
            Text(label, style: const TextStyle(color: RoverColors.textMuted, fontSize: 8, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(value, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
          ],
        ),
      );

  Widget _logicCard() {
    final rows = switch (widget.mode) {
      RoverMode.manual => [
          ('Direction', 'Human'),
          ('AI role', 'None'),
          ('Flow', 'Driver page sends movement commands.'),
        ],
      RoverMode.assisted => [
          ('Direction', 'Human'),
          ('AI role', 'Collision protection'),
          ('Flow', 'Your commands remain primary; the app can block unsafe movement.'),
        ],
      RoverMode.autonomous => [
          ('Direction', 'AI'),
          ('AI role', 'Full navigation'),
          ('Flow', 'Telemetry → local phone policy → safety → STM32.'),
        ],
      RoverMode.followMe => [
          ('Direction', 'AI'),
          ('AI role', 'Target tracking + navigation'),
          ('Flow', 'Scan → target estimate → approach → obstacle avoidance.'),
        ],
    };

    return _panel(
      title: 'MODE LOGIC',
      child: Column(
        children: rows.map((row) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 76, child: Text(row.$1, style: const TextStyle(color: RoverColors.textMuted, fontSize: 9, fontWeight: FontWeight.w800))),
              Expanded(child: Text(row.$2, style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.35))),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _decisionCard() {
    final d = _decision!;
    return _panel(
      title: 'LATEST AI DECISION',
      trailing: Text('${(d.confidence * 100).round()}%', style: const TextStyle(color: RoverColors.radarGreen, fontSize: 11, fontWeight: FontWeight.w900)),
      child: Row(
        children: [
          Icon(_actionIcon(d.action), color: RoverColors.radarGreen, size: 28),
          const SizedBox(width: 12),
          Text(d.label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const Spacer(),
          Text('F ${d.scoreForward.toStringAsFixed(2)}  L ${d.scoreLeft.toStringAsFixed(2)}  R ${d.scoreRight.toStringAsFixed(2)}', style: const TextStyle(color: RoverColors.textMuted, fontSize: 8)),
        ],
      ),
    );
  }

  Widget _actionCard() => _panel(
        title: 'CONTROL',
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _active ? _stop : _activate,
                icon: Icon(_active ? Icons.stop_circle_outlined : Icons.play_arrow_rounded),
                label: Text(_active ? 'STOP MODE' : 'ACTIVATE MODE'),
                style: FilledButton.styleFrom(
                  backgroundColor: _active ? RoverColors.obstacleRed : accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (widget.mode == RoverMode.manual) ...[
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onNavTap?.call(1),
                  icon: const Icon(Icons.gamepad_rounded),
                  label: const Text('DRIVER'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RoverColors.targetCyan,
                    side: const BorderSide(color: RoverColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _safetyCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: RoverColors.obstacleRed.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RoverColors.obstacleRed.withValues(alpha: .22)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, color: RoverColors.obstacleRed, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text('Software mode selection does not replace hardware safety. Keep an emergency stop path available while testing.', style: TextStyle(color: RoverColors.textSecondary, fontSize: 10, height: 1.4))),
          ],
        ),
      );

  Widget _panel({required String title, Widget? trailing, required Widget child}) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: RoverColors.cardBackground, borderRadius: BorderRadius.circular(18), border: Border.all(color: RoverColors.cardBorder)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Text(title, style: const TextStyle(color: RoverColors.textMuted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2)), const Spacer(), if (trailing != null) trailing]),
            const SizedBox(height: 13),
            child,
          ],
        ),
      );

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: .25))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.circle, size: 6, color: color), const SizedBox(width: 5), Text(text, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900))),
      );

  IconData _actionIcon(AiAction action) => switch (action) {
        AiAction.stop => Icons.stop_circle_outlined,
        AiAction.forward => Icons.arrow_upward_rounded,
        AiAction.left => Icons.turn_left_rounded,
        AiAction.right => Icons.turn_right_rounded,
      };

  @override
  void dispose() {
    _decisionSubscription?.cancel();
    super.dispose();
  }
}

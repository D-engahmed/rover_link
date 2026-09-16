import 'dart:async';
import 'package:flutter/material.dart';
import '../models/command_trace.dart';
import '../models/rover_telemetry.dart';
import '../rover/rover_state.dart';
import '../services/bluetooth_service.dart';
import '../services/rover_ai_service.dart';
import '../services/rover_command_service.dart';
import '../services/rover_telemetry_service.dart';
import '../theme/rover_colors.dart';
import '../widgets/rover_bottom_nav.dart';
import 'command_monitor_screen.dart';

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
    this.onNavTap,
    required this.commandService,
    required this.aiService,
    required this.telemetryService,
    required this.bluetoothService,
  });

  @override
  State<ModeScreen> createState() => _ModeScreenState();
}

class _ModeScreenState extends State<ModeScreen> {
  StreamSubscription<RoverTelemetry>? _telemetry;
  StreamSubscription<CommandTrace>? _trace;
  RoverTelemetry? _latest;
  CommandTrace? _lastTrace;
  bool _active = false;
  bool _busy = false;

  String get title => switch (widget.mode) {
        RoverMode.manual => 'MANUAL CONTROL',
        RoverMode.assisted => 'ASSISTED CONTROL',
        RoverMode.autonomous => 'AUTONOMOUS',
        RoverMode.followMe => 'FOLLOW ME',
        RoverMode.emergencyStop => 'EMERGENCY STOP',
      };

  String get description => switch (widget.mode) {
        RoverMode.manual => 'Human chooses every movement. No AI navigation.',
        RoverMode.assisted => 'Human drives. The phone blocks unsafe forward movement when an obstacle is too close.',
        RoverMode.autonomous => 'The phone-side navigation policy chooses movement from live radar telemetry.',
        RoverMode.followMe => 'Experimental target tracking. No camera is used; the app waits for target telemetry.',
        RoverMode.emergencyStop => 'Stop all movement.',
      };

  Color get accent => switch (widget.mode) {
        RoverMode.manual => RoverColors.targetCyan,
        RoverMode.assisted => RoverColors.obstacleAmber,
        RoverMode.autonomous => RoverColors.radarGreen,
        RoverMode.followMe => const Color(0xFFB28CFF),
        RoverMode.emergencyStop => RoverColors.obstacleRed,
      };

  @override
  void initState() {
    super.initState();
    _telemetry = widget.telemetryService.telemetry.listen((t) {
      if (mounted) setState(() => _latest = t);
    });
    _trace = widget.commandService.traces.listen((t) {
      if (mounted) setState(() => _lastTrace = t);
    });
  }

  Future<void> _send(Future<void> Function() fn) async {
    if (_busy || !widget.bluetoothService.isReady) return;
    setState(() => _busy = true);
    try {
      await fn();
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

  Future<void> _assisted(
    Future<void> Function() fn,
    String action,
  ) async {
    final d = _latest?.frontDistanceCm;
    if (action == 'FORWARD' &&
        d != null &&
        d <= RoverAiService.obstacleCm) {
      await _send(() => widget.commandService.stop(source: CommandSource.safety));
      return;
    }
    await _send(fn);
  }

  Future<void> _activate() async {
    if (!widget.bluetoothService.isReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connect the rover in Settings first.')),
        );
      }
      return;
    }

    if (widget.mode == RoverMode.manual) {
      // The STM32 has an explicit mode command. Navigation alone must not
      // change the rover mode because that leaves the firmware in autonomy.
      await _send(() => widget.commandService.manualMode());
      if (mounted) setState(() => _active = true);
      widget.onNavTap?.call(1);
      return;
    }

    if (widget.mode == RoverMode.autonomous) {
      await _send(() => widget.aiService.start());
    } else if (widget.mode == RoverMode.assisted) {
      await _send(() => widget.commandService.manualMode());
    } else if (widget.mode == RoverMode.followMe) {
      setState(() => _active = true);
    }

    if (mounted) setState(() => _active = true);
  }

  Future<void> _stop() async {
    await widget.aiService.stop();
    try {
      await widget.commandService.stop();
    } catch (_) {}
    if (mounted) setState(() => _active = false);
  }

  @override
  Widget build(BuildContext context) {
    final distance = _latest?.frontDistanceCm;
    final aiRunning = widget.aiService.state == AiRunState.running;

    return Scaffold(
      backgroundColor: RoverColors.background,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Command monitor',
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CommandMonitorScreen(
                  commandService: widget.commandService,
                  onNavTap: widget.onNavTap,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: RoverColors.textSecondary,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _row(
                    'Bluetooth',
                    widget.bluetoothService.isReady ? 'READY' : 'DISCONNECTED',
                    widget.bluetoothService.isReady,
                  ),
                  _row(
                    'Front obstacle',
                    distance == null ? '--' : '${distance.toStringAsFixed(0)} cm',
                    distance == null || distance > RoverAiService.obstacleCm,
                  ),
                  _row(
                    'Last TX',
                    _lastTrace == null
                        ? '--'
                        : '${_lastTrace!.action} / ${_lastTrace!.stageLabel}',
                    _lastTrace?.stage == CommandStage.sent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (widget.mode == RoverMode.manual || widget.mode == RoverMode.assisted)
              _drivePad(),
            if (widget.mode == RoverMode.autonomous) _aiPanel(aiRunning),
            if (widget.mode == RoverMode.followMe) _followPanel(),
            const SizedBox(height: 14),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COMMAND PIPELINE',
                    style: TextStyle(
                      color: RoverColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'source → safety → Bluetooth TX → STM32',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'SENT means the Bluetooth write succeeded. STM32 execution is confirmed by the firmware ACK.',
                    style: TextStyle(
                      color: RoverColors.textMuted,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CommandMonitorScreen(
                          commandService: widget.commandService,
                          onNavTap: widget.onNavTap,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: const Text('OPEN COMMAND MONITOR'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: RoverBottomNav(
        currentIndex: 0,
        onTap: widget.onNavTap,
      ),
    );
  }

  Widget _drivePad() => _card(
        child: Column(
          children: [
            Text(
              widget.mode == RoverMode.assisted
                  ? 'HUMAN INPUT + SAFETY FILTER'
                  : 'MANUAL DRIVER',
              style: const TextStyle(
                color: RoverColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _btn(
                  'LEFT',
                  Icons.chevron_left,
                  () => widget.mode == RoverMode.assisted
                      ? _assisted(() => widget.commandService.turnLeft(), 'LEFT')
                      : _send(() => widget.commandService.turnLeft()),
                ),
                const SizedBox(width: 9),
                _btn(
                  'STOP',
                  Icons.stop_rounded,
                  () => _send(() => widget.commandService.stop()),
                  danger: true,
                ),
                const SizedBox(width: 9),
                _btn(
                  'RIGHT',
                  Icons.chevron_right,
                  () => widget.mode == RoverMode.assisted
                      ? _assisted(() => widget.commandService.turnRight(), 'RIGHT')
                      : _send(() => widget.commandService.turnRight()),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _btn(
                  'BACK',
                  Icons.keyboard_arrow_down,
                  () => _send(() => widget.commandService.moveBackward()),
                ),
                const SizedBox(width: 9),
                _btn(
                  'FORWARD',
                  Icons.keyboard_arrow_up,
                  () => widget.mode == RoverMode.assisted
                      ? _assisted(
                          () => widget.commandService.moveForward(),
                          'FORWARD',
                        )
                      : _send(() => widget.commandService.moveForward()),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _aiPanel(bool running) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI NAVIGATION',
              style: TextStyle(
                color: RoverColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              running
                  ? 'AI is selecting movement from live radar telemetry.'
                  : 'AI is stopped.',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : (running ? _stop : _activate),
                icon: Icon(running ? Icons.stop : Icons.smart_toy_rounded),
                label: Text(
                  running ? 'STOP AUTONOMOUS' : 'START AUTONOMOUS',
                ),
              ),
            ),
          ],
        ),
      );

  Widget _followPanel() {
    final d = _latest?.targetDistanceCm;
    final a = _latest?.targetAngleDeg;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TARGET ACQUISITION',
            style: TextStyle(
              color: RoverColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          _row('Target distance', d == null ? 'WAITING' : '${d.toStringAsFixed(0)} cm', d != null),
          _row('Target angle', a == null ? 'WAITING' : '${a.toStringAsFixed(0)}°', a != null),
          _row('Follow state', _active ? 'ARMED' : 'STOPPED', _active),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : (_active ? _stop : _activate),
              icon: Icon(_active ? Icons.stop : Icons.person_search_rounded),
              label: Text(_active ? 'STOP FOLLOW ME' : 'ARM FOLLOW ME'),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No camera is used. Human identity classification is not claimed from a single HC-SR04 reading.',
            style: TextStyle(
              color: RoverColors.textMuted,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(
    String label,
    IconData icon,
    VoidCallback fn, {
    bool danger = false,
  }) => SizedBox(
        width: 88,
        child: ElevatedButton(
          onPressed: _busy ? null : fn,
          style: ElevatedButton.styleFrom(
            backgroundColor: danger
                ? RoverColors.obstacleRed.withValues(alpha: .18)
                : RoverColors.cardHighlight,
            foregroundColor: danger ? RoverColors.obstacleRed : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RoverColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: RoverColors.cardBorder),
        ),
        child: child,
      );

  Widget _row(String label, String value, bool good) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: RoverColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: good ? RoverColors.radarGreen : RoverColors.obstacleRed,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );

  @override
  void dispose() {
    _telemetry?.cancel();
    _trace?.cancel();
    super.dispose();
  }
}

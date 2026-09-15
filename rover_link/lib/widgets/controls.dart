import 'package:flutter/material.dart';
import '../state/rover_state.dart';

const _cyan = Color(0xFF57D6FF);
const _line = Color(0xFF16324A);
const _muted = Color(0xFF5F8296);
const _panel = Color(0xFF0A1420);
const _bg = Color(0xFF050B13);
const _ok = Color(0xFF5EE08A);
const _warn = Color(0xFFFFB100);
const _crit = Color(0xFFFF4D4D);

class SafetyStrip extends StatelessWidget {
  final RoverState state;
  const SafetyStrip({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state.safetyState;
    final color = s == 'crit' ? _crit : s == 'caution' ? _warn : _ok;
    final bg = s == 'crit'
        ? const Color(0xFF1A0B0B)
        : s == 'caution'
            ? const Color(0xFF181206)
            : const Color(0xFF0D1420);
    final obstacleText =
        state.nearestObstacleCm == null ? '— cm' : '${state.nearestObstacleCm!.round()} cm';
    final sub = state.estopped
        ? 'Motors locked — press RESET to re-arm'
        : state.nearestObstacleCm == null
            ? 'Ultrasonic sweep idle — connect to start reading'
            : s == 'crit'
                ? 'Too close — motors held'
                : s == 'caution'
                    ? 'Obstacle nearby — reduce speed'
                    : 'Path clear';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(children: [
                    const TextSpan(
                        text: 'NEAREST OBSTACLE  ',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    TextSpan(
                        text: obstacleText,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  ]),
                ),
                Text(sub, style: const TextStyle(fontSize: 10, color: _muted)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => state.toggleEstop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: state.estopped ? _muted : _crit,
              foregroundColor: state.estopped ? const Color(0xFF0A0D10) : const Color(0xFF1A0000),
            ),
            child: Text(state.estopped ? 'RESET' : 'STOP',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class ModeSwitch extends StatelessWidget {
  final RoverState state;
  const ModeSwitch({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(children: [
        Expanded(
            child: _segButton('MANUAL DRIVE', state.mode == DriveMode.manual,
                () => state.setMode(DriveMode.manual))),
        const SizedBox(width: 8),
        Expanded(
            child: _segButton('FOLLOW ME', state.mode == DriveMode.follow,
                () => state.setMode(DriveMode.follow))),
      ]),
    );
  }
}

class QuickMacros extends StatelessWidget {
  final RoverState state;
  const QuickMacros({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _macro('STATUS', 'STATUS', state),
          _macro('RADAR', 'RADAR_SWEEP', state),
          _macro('CALIB', 'CALIB_RSSI', state),
          _macro('STOP', 'STOP', state, danger: true),
        ]),
      ),
    );
  }
}

Widget _macro(String label, String cmd, RoverState state, {bool danger = false}) => Padding(
      padding: const EdgeInsets.only(right: 6),
      child: OutlinedButton(
        onPressed: () => state.sendMacro(cmd),
        style: OutlinedButton.styleFrom(
          foregroundColor: danger ? _crit : _cyan,
          side: BorderSide(color: danger ? const Color(0xFF7A2020) : _line),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5)),
      ),
    );

Widget _segButton(String label, bool on, VoidCallback onTap) => OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: on ? _cyan : Colors.transparent,
        foregroundColor: on ? const Color(0xFF001824) : _muted,
        side: const BorderSide(color: _line),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    );

class ManualDrivePanel extends StatelessWidget {
  final RoverState state;
  const ManualDrivePanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          color: _panel, border: Border.all(color: _line), borderRadius: BorderRadius.circular(6)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('MANUAL DRIVE',
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.bold, color: _cyan, letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _DPad(state: state),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('MOTOR SPEED',
                    style: TextStyle(fontSize: 10.5, color: _muted, fontWeight: FontWeight.w600)),
                Text('${state.speedPercent}% · PWM ${(state.speedPercent / 100 * 255).round()}',
                    style: const TextStyle(fontSize: 10.5, color: _muted)),
              ]),
              Slider(
                value: state.speedPercent.toDouble(),
                min: 0,
                max: 100,
                activeColor: _cyan,
                onChanged: (v) => state.setSpeed(v.round()),
              ),
              Text('Last command: ${state.lastCommand}',
                  style: const TextStyle(fontSize: 10.5, color: _muted)),
            ]),
          ),
        ]),
      ]),
    );
  }
}

class _DPad extends StatelessWidget {
  final RoverState state;
  const _DPad({required this.state});

  @override
  Widget build(BuildContext context) {
    final locked = !state.connected || state.estopped;

    Widget key_(String label, String code, String cmdLabel) => SizedBox(
          width: 38,
          height: 38,
          child: ElevatedButton(
            onPressed: locked ? null : () => state.drive(code, cmdLabel),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D1A26),
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero),
            child: Text(label),
          ),
        );

    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(children: [
        Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: _bg, border: Border.all(color: _line)),
        ),
        Positioned(top: 4, left: 47, child: key_('▲', 'F', 'FORWARD')),
        Positioned(left: 4, top: 47, child: key_('◀', 'L', 'LEFT')),
        Positioned(right: 4, top: 47, child: key_('▶', 'R', 'RIGHT')),
        Positioned(bottom: 4, left: 47, child: key_('▼', 'B', 'BACK')),
        Positioned(
          top: 47,
          left: 47,
          child: SizedBox(
            width: 38,
            height: 38,
            child: ElevatedButton(
              onPressed: locked ? null : () => state.drive('S', 'STOP'),
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: const Color(0xFF2A0D0D),
                foregroundColor: _crit,
                padding: EdgeInsets.zero,
              ),
              child: const Text('●', style: TextStyle(fontSize: 9)),
            ),
          ),
        ),
      ]),
    );
  }
}

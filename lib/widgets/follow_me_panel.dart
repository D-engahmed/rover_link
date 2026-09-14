import 'dart:math';
import 'package:flutter/material.dart';
import '../state/rover_state.dart';

const _cyan = Color(0xFF57D6FF);
const _line = Color(0xFF16324A);
const _muted = Color(0xFF5F8296);
const _panel = Color(0xFF0A1420);
const _amber = Color(0xFFFFB400);
const _ok = Color(0xFF5EE08A);

class FollowMePanel extends StatefulWidget {
  final RoverState state;
  const FollowMePanel({super.key, required this.state});

  @override
  State<FollowMePanel> createState() => _FollowMePanelState();
}

class _FollowMePanelState extends State<FollowMePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweepCtrl;

  @override
  void initState() {
    super.initState();
    _sweepCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))
          ..repeat();
  }

  @override
  void dispose() {
    _sweepCtrl.dispose();
    super.dispose();
  }

  String _bearingNote(BearingSource s) {
    switch (s) {
      case BearingSource.compassImu:
        return 'Locked — needs a magnetometer or IMU (e.g. HMC5883L / MPU6050 with sensor fusion) on the STM32. Not installed yet.';
      case BearingSource.camera:
        return 'Uses the phone camera + face detection: frames the person, steers toward them, and reads head angle for "facing the rover" — this is what drives the door trigger.';
      case BearingSource.gradientSearch:
        return 'No angle sensor on the board yet — the rover turns a little, checks whether RSSI got stronger or weaker, and steers toward the improving side.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Column(children: [
      Row(children: [
        Expanded(
            child: _seg('GRADIENT', s.bearingSource == BearingSource.gradientSearch,
                () => s.setBearingSource(BearingSource.gradientSearch))),
        const SizedBox(width: 6),
        Expanded(
            child: _seg('COMPASS/IMU', s.bearingSource == BearingSource.compassImu,
                () => s.setBearingSource(BearingSource.compassImu))),
        const SizedBox(width: 6),
        Expanded(
            child: _seg('CAMERA', s.bearingSource == BearingSource.camera,
                () => s.setBearingSource(BearingSource.camera))),
      ]),
      const SizedBox(height: 10),
      _card('',
          child: Text(_bearingNote(s.bearingSource),
              style: const TextStyle(fontSize: 10, color: _muted, fontFamily: 'monospace'))),
      _card('TARGET ESTIMATE', child: Column(children: [
        _kv(
            'Distance (RSSI-derived)',
            s.targetDistanceCm == null
                ? '— m'
                : '${(s.targetDistanceCm! / 100).toStringAsFixed(2)} m'),
        _kv(s.bearingSource == BearingSource.compassImu ? 'Heading' : 'Steering',
            s.steeringText),
        const SizedBox(height: 4),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Distance is filtered RSSI, not measured range — typical error ±30% on RSSI alone.',
            style: TextStyle(fontSize: 9.5, color: _muted, fontFamily: 'monospace'),
          ),
        ),
      ])),
      if (s.bearingSource == BearingSource.camera)
        _card('PERSON DETECTION (camera)', child: Column(children: [
          _kv('In frame', s.lastSighting.present ? 'YES' : 'no'),
          _kv('Facing rover', s.lastSighting.present
              ? (s.lastSighting.facingCamera ? 'YES' : 'no — turned away')
              : '—'),
          _kv('Door', s.doorOpen ? 'OPEN' : 'closed'),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Door opens automatically once the person is centered, facing the rover, and the ultrasonic reads inside the approach threshold.',
              style: TextStyle(fontSize: 9.5, color: _muted, fontFamily: 'monospace'),
            ),
          ),
        ])),
      _card('LIVE SWEEP', child: Center(
        child: SizedBox(
          width: 180,
          height: 180,
          child: AnimatedBuilder(
            animation: _sweepCtrl,
            builder: (context, _) =>
                CustomPaint(painter: _RadarPainter(_sweepCtrl.value * 2 * pi)),
          ),
        ),
      )),
      _card('APPROACH LOG — distance trend, not a map', child: SizedBox(
        height: 56,
        width: double.infinity,
        child: CustomPaint(painter: _SparkPainter(s.distanceHistoryCm)),
      )),
      _card('STEERING & SENSOR LOG', child: SizedBox(
        height: 118,
        child: s.aiLog.isEmpty
            ? const Center(
                child: Text('No activity yet.',
                    style: TextStyle(color: _muted, fontFamily: 'monospace', fontSize: 11)))
            : ListView.builder(
                reverse: true,
                itemCount: s.aiLog.length,
                itemBuilder: (context, i) {
                  final e = s.aiLog[s.aiLog.length - 1 - i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${_fmtTime(e.time)}  ${e.text}',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontFamily: 'monospace',
                          color: e.emphasis ? _amber : const Color(0xFFA9D8EC)),
                    ),
                  );
                },
              ),
      )),
    ]);
  }

  Widget _seg(String label, bool on, VoidCallback onTap) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: on ? _cyan : Colors.transparent,
          foregroundColor: on ? const Color(0xFF001824) : _muted,
          side: const BorderSide(color: _line),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
      );

  Widget _card(String title, {required Widget child}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: _panel, border: Border.all(color: _line), borderRadius: BorderRadius.circular(6)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 10.5, fontWeight: FontWeight.bold, color: _cyan, letterSpacing: 1)),
            ),
          child,
        ]),
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k, style: const TextStyle(fontSize: 12, color: Colors.white)),
          Text(v,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: v == 'OPEN' ? _ok : Colors.white)),
        ]),
      );

  String _fmtTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
}

class _RadarPainter extends CustomPainter {
  final double angle;
  _RadarPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2;
    final gridPaint = Paint()
      ..color = const Color(0xFF123045)
      ..style = PaintingStyle.stroke;
    for (final f in [1.0, 0.65, 0.32]) {
      canvas.drawCircle(center, r * f, gridPaint);
    }
    canvas.drawLine(
        Offset(center.dx, 0), Offset(center.dx, size.height), Paint()..color = const Color(0xFF0D2434));
    canvas.drawLine(
        Offset(0, center.dy), Offset(size.width, center.dy), Paint()..color = const Color(0xFF0D2434));

    final sweepEnd =
        Offset(center.dx + r * 0.9 * sin(angle), center.dy - r * 0.9 * cos(angle));
    canvas.drawLine(center, sweepEnd, Paint()..color = _cyan..strokeWidth = 2);

    canvas.drawCircle(Offset(center.dx + r * 0.35, center.dy - r * 0.2), 3, Paint()..color = _amber);
    canvas.drawCircle(Offset(center.dx - r * 0.28, center.dy + r * 0.35), 3, Paint()..color = _amber);
    canvas.drawCircle(center, 3.5, Paint()..color = _cyan);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => oldDelegate.angle != angle;
}

class _SparkPainter extends CustomPainter {
  final List<double> data;
  _SparkPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2),
        Paint()..color = const Color(0xFF123045));
    if (data.length < 2) return;
    const min = 50.0, max = 380.0;
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final v = data[i].clamp(min, max);
      final y = size.height - ((v - min) / (max - min)) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, Paint()
      ..color = _cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) => true;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/rover_state.dart';
import '../theme/app_theme.dart';

/// The shared radar visualization used on Home and the full Radar screen.
/// Everything is drawn in polar coordinates around the rover at the center,
/// matching the coordinate system described in the UI spec (0° = forward).
class RadarView extends StatefulWidget {
  const RadarView({
    super.key,
    required this.targetBearingDeg,
    required this.targetDistanceM,
    required this.obstacles,
    this.maxRangeM = 6.0,
    this.showLabels = true,
  });

  final double targetBearingDeg;
  final double targetDistanceM;
  final List<RadarObstacle> obstacles;
  final double maxRangeM;
  final bool showLabels;

  @override
  State<RadarView> createState() => _RadarViewState();
}

class _RadarViewState extends State<RadarView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _RadarPainter(
            sweepAngle: _controller.value * 2 * math.pi,
            targetBearingDeg: widget.targetBearingDeg,
            targetDistanceM: widget.targetDistanceM,
            obstacles: widget.obstacles,
            maxRangeM: widget.maxRangeM,
            showLabels: widget.showLabels,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.sweepAngle,
    required this.targetBearingDeg,
    required this.targetDistanceM,
    required this.obstacles,
    required this.maxRangeM,
    required this.showLabels,
  });

  final double sweepAngle;
  final double targetBearingDeg;
  final double targetDistanceM;
  final List<RadarObstacle> obstacles;
  final double maxRangeM;
  final bool showLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 12;

    // Background rings
    final ringPaint = Paint()
      ..color = RoverColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final f in [0.33, 0.66, 1.0]) {
      canvas.drawCircle(center, radius * f, ringPaint);
    }

    // Cross lines
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), ringPaint);
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), ringPaint);

    // Rotating sweep line with a fading trail
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [RoverColors.green.withOpacity(0.0), RoverColors.green.withOpacity(0.6)],
        startAngle: sweepAngle - 0.9,
        endAngle: sweepAngle,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      sweepAngle - 0.9,
      0.9,
      true,
      sweepPaint,
    );

    // Obstacles (angle: 0 = forward/up, clockwise)
    final obstaclePaint = Paint()..color = RoverColors.amber;
    for (final o in obstacles) {
      final rad = (o.angleDeg - 90) * math.pi / 180;
      final r = (o.distanceM / maxRangeM).clamp(0.0, 1.0) * radius;
      final pos = Offset(center.dx + r * math.cos(rad), center.dy + r * math.sin(rad));
      canvas.drawCircle(pos, 4, obstaclePaint);
      canvas.drawCircle(
          pos, 8, Paint()..color = RoverColors.amber.withOpacity(0.25));
    }

    // Target (bearing is relative to rover heading, 0 = straight ahead)
    final targetRad = (targetBearingDeg - 90) * math.pi / 180;
    final targetR = (targetDistanceM / maxRangeM).clamp(0.0, 1.0) * radius;
    final targetPos =
        Offset(center.dx + targetR * math.cos(targetRad), center.dy + targetR * math.sin(targetRad));
    canvas.drawCircle(targetPos, 9, Paint()..color = RoverColors.cyan.withOpacity(0.25));
    canvas.drawCircle(targetPos, 5, Paint()..color = RoverColors.cyan);

    // Rover, always centered
    canvas.drawCircle(center, 7, Paint()..color = RoverColors.text);
    canvas.drawCircle(center, 11, Paint()
      ..color = RoverColors.text.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    if (showLabels) {
      _drawLabel(canvas, '0°', Offset(center.dx + radius + 4, center.dy - 6));
      _drawLabel(canvas, '90°', Offset(center.dx - 10, center.dy - radius - 18));
      _drawLabel(canvas, '180°', Offset(center.dx - radius - 34, center.dy - 6));
      _drawLabel(canvas, '270°', Offset(center.dx - 12, center.dy + radius + 4));
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(color: RoverColors.muted, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.targetBearingDeg != targetBearingDeg ||
        oldDelegate.targetDistanceM != targetDistanceM ||
        oldDelegate.obstacles != obstacles;
  }
}

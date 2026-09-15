import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/radar_detection.dart';
import '../theme/rover_colors.dart';

class RadarScope extends StatefulWidget {
  final List<RadarDetection> detections;
  final double maxDistance;

  const RadarScope({
    super.key,
    required this.detections,
    this.maxDistance = 8.0,
  });

  @override
  State<RadarScope> createState() => _RadarScopeState();
}

class _RadarScopeState extends State<RadarScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Resolve available width safely. If unconstrained, fall back to screen width.
        double availableWidth = constraints.maxWidth;
        if (!availableWidth.isFinite) {
          final screenWidth = MediaQuery.sizeOf(context).width;
          availableWidth = screenWidth > 0 ? screenWidth : 0.0;
        }

        // If the surface or layout pass has no positive width yet (e.g. Android startup),
        // safely return SizedBox.shrink() so zero-dimension surfaces are not drawn.
        if (availableWidth <= 0.0) {
          return const SizedBox.shrink();
        }

        // Radar diameter capped at 330dp
        final double radarSize = math.min(availableWidth, 330.0);
        if (radarSize <= 0.0) {
          return const SizedBox.shrink();
        }

        return Center(
          child: SizedBox(
            width: radarSize,
            height: radarSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // CustomPaint driven directly by the animation controller via repaint listener
                CustomPaint(
                  size: Size(radarSize, radarSize),
                  painter: _RadarPainter(
                    animation: _sweepController,
                    detections: widget.detections,
                    maxDistance: widget.maxDistance,
                  ),
                ),

                // Cardinal Angle Labels: 0°, 90°, 180°, 270° (when sufficient room)
                if (radarSize >= 80) ...[
                  _buildCardinalLabel('0°', top: 4, left: null, right: null, bottom: null),
                  _buildCardinalLabel('90°', top: null, left: null, right: 4, bottom: null),
                  _buildCardinalLabel('180°', top: null, left: null, right: null, bottom: 4),
                  _buildCardinalLabel('270°', top: null, left: 4, right: null, bottom: null),
                ],

                // Center Rover marker
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: RoverColors.radarGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: RoverColors.radarGreen.withValues(alpha: 0.8),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardinalLabel(
    String text, {
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: RoverColors.background.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: RoverColors.cardBorder.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: RoverColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Animation<double> animation;
  final List<RadarDetection> detections;
  final double maxDistance;

  // Cache text painters to avoid expensive HarfBuzz text shaping every animation tick
  TextPainter? _rangeTextPainter;
  final Map<String, TextPainter> _detectionTextPainters = {};

  _RadarPainter({
    required this.animation,
    required this.detections,
    required this.maxDistance,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final double minDim = math.min(size.width, size.height);
    if (minDim <= 0.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radarRadius = math.max(0.0, (minDim / 2) - 22.0);
    if (radarRadius <= 0.0) return;

    final double sweepAngle = animation.value * 2 * math.pi;

    // 1. Radar background circular disc
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0F1A2E).withValues(alpha: 0.95),
          const Color(0xFF090E18).withValues(alpha: 0.98),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radarRadius));
    canvas.drawCircle(center, radarRadius, bgPaint);

    // 2. Concentric Distance Rings (4 rings: 25%, 50%, 75%, 100%)
    final ringPaint = Paint()
      ..color = RoverColors.radarRing
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final outerRingPaint = Paint()
      ..color = RoverColors.radarGreen.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 1; i <= 4; i++) {
      final r = radarRadius * (i / 4.0);
      canvas.drawCircle(center, r, i == 4 ? outerRingPaint : ringPaint);
    }

    // 3. Range labels on vertical axis (e.g. 2m, 4m, 6m, 8m)
    _rangeTextPainter ??= TextPainter(textDirection: TextDirection.ltr);
    for (int i = 1; i <= 4; i++) {
      final dist = (maxDistance * (i / 4.0)).toStringAsFixed(0);
      final r = radarRadius * (i / 4.0);
      _rangeTextPainter!.text = TextSpan(
        text: '${dist}m',
        style: TextStyle(
          color: RoverColors.radarGreen.withValues(alpha: 0.6),
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      );
      _rangeTextPainter!.layout();
      _rangeTextPainter!.paint(canvas, Offset(center.dx + 4, center.dy - r - 2));
    }

    // 4. Crosshairs and Diagonal Grid Lines
    final crosshairPaint = Paint()
      ..color = RoverColors.radarCrosshair
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    // North-South & East-West crosshairs
    canvas.drawLine(
      Offset(center.dx, center.dy - radarRadius),
      Offset(center.dx, center.dy + radarRadius),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radarRadius, center.dy),
      Offset(center.dx + radarRadius, center.dy),
      crosshairPaint,
    );

    // 45° Diagonal grid lines
    final diagPaint = Paint()
      ..color = RoverColors.radarCrosshair.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final cos45 = radarRadius * 0.7071;
    canvas.drawLine(
      Offset(center.dx - cos45, center.dy - cos45),
      Offset(center.dx + cos45, center.dy + cos45),
      diagPaint,
    );
    canvas.drawLine(
      Offset(center.dx - cos45, center.dy + cos45),
      Offset(center.dx + cos45, center.dy - cos45),
      diagPaint,
    );

    // 5. Perimeter Tick Marks (every 30 degrees)
    final tickPaint = Paint()
      ..color = RoverColors.radarGreen.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    for (int deg = 0; deg < 360; deg += 30) {
      if (deg % 90 == 0) continue; // Skip cardinal directions
      final rad = deg * (math.pi / 180);
      final p1 = Offset(
        center.dx + (radarRadius - 4) * math.cos(rad),
        center.dy + (radarRadius - 4) * math.sin(rad),
      );
      final p2 = Offset(
        center.dx + radarRadius * math.cos(rad),
        center.dy + radarRadius * math.sin(rad),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // 6. Green Radar Sweep Sector (using drawArc for efficient hardware-accelerated rendering)
    final double sweepSpan = 55 * (math.pi / 180); // 55 degrees
    final double sweepStartAngle = sweepAngle - sweepSpan;
    final radarRect = Rect.fromCircle(center: center, radius: radarRadius);

    final sweepSectorPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: sweepSpan,
        colors: [
          Colors.transparent,
          RoverColors.radarGreen.withValues(alpha: 0.06),
          RoverColors.radarGreen.withValues(alpha: 0.28),
        ],
        stops: const [0.0, 0.45, 1.0],
        transform: GradientRotation(sweepStartAngle),
      ).createShader(radarRect);

    canvas.drawArc(radarRect, sweepStartAngle, sweepSpan, true, sweepSectorPaint);

    // Leading sweep line: dual-pass glow without MaskFilter to prevent GPU/Impeller crashes
    final leadingLineEnd = Offset(
      center.dx + radarRadius * math.cos(sweepAngle),
      center.dy + radarRadius * math.sin(sweepAngle),
    );

    final glowLinePaint = Paint()
      ..color = RoverColors.radarSweepEdge.withValues(alpha: 0.35)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, leadingLineEnd, glowLinePaint);

    final sweepLinePaint = Paint()
      ..color = RoverColors.radarSweepEdge
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, leadingLineEnd, sweepLinePaint);

    // 7. Render Target and Obstacle Blip Dots
    for (final detection in detections) {
      final double rad = (detection.bearing - 90) * (math.pi / 180);
      final double clampedDist = detection.distance.clamp(0.0, maxDistance);
      final double r = (clampedDist / maxDistance) * radarRadius;

      final blipOffset = Offset(
        center.dx + r * math.cos(rad),
        center.dy + r * math.sin(rad),
      );

      // Outer glowing pulse ring
      final outerGlowPaint = Paint()
        ..color = detection.color.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(blipOffset, 9.0, outerGlowPaint);

      // Mid glow (safe alpha fill without GPU MaskFilter)
      final midGlowPaint = Paint()
        ..color = detection.color.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(blipOffset, 5.5, midGlowPaint);

      // Solid color dot
      final dotColorPaint = Paint()
        ..color = detection.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(blipOffset, 4.0, dotColorPaint);

      // Inner solid bright core dot
      final corePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(blipOffset, 2.0, corePaint);

      // Distance & ID tag text near the blip (cached to eliminate main-thread text layout stalls)
      final labelKey = '${detection.id}_${detection.distance}';
      final tp = _detectionTextPainters.putIfAbsent(labelKey, () {
        final labelText = detection.isTarget ? 'YOU' : 'OBS';
        final painter = TextPainter(
          textDirection: TextDirection.ltr,
          text: TextSpan(
            text: '$labelText ${detection.distance.toStringAsFixed(1)}m',
            style: TextStyle(
              color: detection.color,
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
              ],
            ),
          ),
        );
        painter.layout();
        return painter;
      });

      // Position text smartly offset from dot
      double textX = blipOffset.dx + 6;
      double textY = blipOffset.dy - 6;
      if (textX + tp.width > size.width - 20) {
        textX = blipOffset.dx - tp.width - 6;
      }
      if (textY < 25) {
        textY = blipOffset.dy + 6;
      }

      tp.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.maxDistance != maxDistance;
  }
}

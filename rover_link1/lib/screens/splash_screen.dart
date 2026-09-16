import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/rover_colors.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: .92, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 1450), widget.onFinished);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoverColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _StartupGridPainter())),
          Positioned(top: -90, right: -70, child: _Glow(color: RoverColors.targetCyan, size: 260)),
          Positioned(bottom: -120, left: -100, child: _Glow(color: RoverColors.radarGreen, size: 300)),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 116,
                          height: 116,
                          decoration: BoxDecoration(
                            color: RoverColors.cardBackground.withValues(alpha: .82),
                            shape: BoxShape.circle,
                            border: Border.all(color: RoverColors.radarGreen.withValues(alpha: .5), width: 1.5),
                            boxShadow: [BoxShadow(color: RoverColors.radarGreen.withValues(alpha: .16), blurRadius: 40, spreadRadius: 3)],
                          ),
                          child: const Icon(Icons.smart_toy_rounded, size: 52, color: RoverColors.radarGreen),
                        ),
                        const SizedBox(height: 28),
                        const Text('ROVER LINK', style: TextStyle(color: RoverColors.textPrimary, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 3)),
                        const SizedBox(height: 8),
                        const Text('INTELLIGENT ROVER CONTROL SYSTEM', textAlign: TextAlign.center, style: TextStyle(color: RoverColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
                        const SizedBox(height: 26),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: RoverColors.cardBackground.withValues(alpha: .72), borderRadius: BorderRadius.circular(30), border: Border.all(color: RoverColors.cardBorder)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.memory_rounded, size: 14, color: RoverColors.targetCyan),
                            SizedBox(width: 7),
                            Text('STM32  •  HC-05  •  HC-SR04', style: TextStyle(color: RoverColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: .8)),
                          ]),
                        ),
                        const SizedBox(height: 34),
                        SizedBox(width: 150, child: ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(minHeight: 3, backgroundColor: RoverColors.cardBorder, valueColor: const AlwaysStoppedAnimation<Color>(RoverColors.radarGreen)))),
                        const SizedBox(height: 12),
                        const Text('INITIALIZING CONTROL INTERFACE', style: TextStyle(color: RoverColors.textMuted, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                        const SizedBox(height: 52),
                        const Text('ROVER LINK  •  LOCAL CONTROL', style: TextStyle(color: RoverColors.textMuted, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => IgnorePointer(child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withValues(alpha: .10), color.withValues(alpha: 0)]))));
}

class _StartupGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .025)..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += step) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

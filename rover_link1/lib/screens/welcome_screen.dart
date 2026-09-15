 
import 'dart:async';

import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback? onFinished;

  const WelcomeScreen({
    super.key,
    this.onFinished,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  Timer? _timer;

  @override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _timer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        widget.onFinished?.call();
      }
    });
  });
}

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF20252B),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ============================================================
              // LOGO AREA
              // ============================================================
              // This is the temporary placeholder.
              // Later we will replace it with the real Rover Link logo asset.
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF19D7C5),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF19D7C5).withValues(alpha: 0.25),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 105,
                      height: 105,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00B8D4),
                          width: 2,
                        ),
                      ),
                    ),
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 2,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.smart_toy_rounded,
                      size: 42,
                      color: Color(0xFF69F0AE),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 34),

              // ============================================================
              // APP NAME
              // ============================================================
              const Text(
                'ROVER LINK',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                ),
              ),

              const SizedBox(height: 10),

              // ============================================================
              // SUBTITLE
              // ============================================================
              const Text(
                'STM32F401 · SMART INTEGRATION',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF9AA7B5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.1,
                ),
              ),

              const Spacer(flex: 3),

              // ============================================================
              // CONNECTING
              // ============================================================
              const Text(
                'Connecting...',
                style: TextStyle(
                  color: Color(0xFF8FAF9D),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 14),

              // ============================================================
              // PROGRESS RING
              // ============================================================
              SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  value: 0.25,
                  strokeWidth: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF69F0AE),
                  ),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
 

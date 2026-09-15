import 'package:flutter/material.dart';
import '../theme/rover_colors.dart';
import '../widgets/rover_bottom_nav.dart';
import '../services/rover_command_service.dart';

class DriveScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTap;
 final RoverCommandService roverCommandService;

  const DriveScreen({
    super.key,
    this.onNavTap,
    required this.roverCommandService,
  });

  @override
  State<DriveScreen> createState() => _DriveScreenState();
}

class _DriveScreenState extends State<DriveScreen> {
  // Speed slider local state (0 - 100, default 65%)
  double _speed = 65.0;

  // Active directional button (for visual feedback)
  String? _activeDirection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoverColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Title Header
            _buildHeader(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // D-PAD Directional Controls Section
                    _buildDPadSection(),
                    const SizedBox(height: 16),

                    // SPEED Panel Card
                    _buildSpeedPanel(),
                    const SizedBox(height: 16),

                    // OBSTACLE & ULTRASONIC Information Card
                    _buildObstacleUltrasonicCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar with Drive (index 1) active
      bottomNavigationBar: RoverBottomNav(
        currentIndex: 1,
        onTap: widget.onNavTap,
      ),
    );
  }

  /// 1. HEADER:
  /// - MANUAL DRIVE
  /// - Large, bold, white text.
  /// - Visually consistent with existing Home/Radar screens.
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: RoverColors.background,
        border: Border(
          bottom: BorderSide(
            color: RoverColors.cardBorder,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MANUAL DRIVE',
                style: TextStyle(
                  color: RoverColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'DIRECT MOTOR CONTROL',
                style: TextStyle(
                  color: RoverColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: RoverColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: RoverColors.cardBorder,
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: RoverColors.targetCyan,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: RoverColors.targetCyan.withValues(alpha: 0.8),
                        blurRadius: 6,
                        spreadRadius: 1.5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'READY',
                  style: TextStyle(
                    color: RoverColors.targetCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. MANUAL DRIVE CONTROL:
  /// 5 circular buttons arranged like a D-pad:
  ///              ↑
  ///        ←     🔴     →
  ///              ↓
  Widget _buildDPadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: RoverColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: RoverColors.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: UP button
          _buildDirectionButton(
            icon: Icons.keyboard_arrow_up_rounded,
            direction: 'UP',
          ),
          const SizedBox(height: 12),

          // Row 2: LEFT - STOP - RIGHT
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDirectionButton(
                icon: Icons.keyboard_arrow_left_rounded,
                direction: 'LEFT',
              ),
              const SizedBox(width: 16),

              // CENTER: STOP button (Red, circular, clearly labeled)
              _buildStopButton(),

              const SizedBox(width: 16),
              _buildDirectionButton(
                icon: Icons.keyboard_arrow_right_rounded,
                direction: 'RIGHT',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 3: DOWN button
          _buildDirectionButton(
            icon: Icons.keyboard_arrow_down_rounded,
            direction: 'DOWN',
          ),
        ],
      ),
    );
  }

  /// Circular Directional Button (UP, LEFT, RIGHT, DOWN)
   Widget _buildDirectionButton({
  required IconData icon,
  required String direction,
}) {
  final bool isActive = _activeDirection == direction;

  return GestureDetector(
    onTapDown: (_) async {
      setState(() {
        _activeDirection = direction;
      });

      try {
        switch (direction) {
          case 'UP':
            await widget.roverCommandService.moveForward();
            break;

          case 'LEFT':
            await widget.roverCommandService.turnLeft();
            break;

          case 'RIGHT':
            await widget.roverCommandService.turnRight();
            break;

          case 'DOWN':
            await widget.roverCommandService.moveBackward();
            break;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bluetooth error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    },
    onTapUp: (_) {
      setState(() {
        _activeDirection = null;
      });
    },
    onTapCancel: () {
      setState(() {
        _activeDirection = null;
      });
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: isActive
            ? RoverColors.targetCyan.withValues(alpha: 0.25)
            : const Color(0xFF162035),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive
              ? RoverColors.targetCyan
              : RoverColors.cardBorder,
          width: isActive ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? RoverColors.targetCyan.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: isActive ? 12 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: 34,
          color: isActive
              ? RoverColors.targetCyan
              : Colors.white,
        ),
      ),
    ),
  );
}

  /// Center STOP Button:
  /// - Circular button
  /// - Red
  /// - Clearly labeled STOP
  /// - Visually distinct from directional buttons
  Widget _buildStopButton() {
    final bool isActive = _activeDirection == 'STOP';

    return GestureDetector(
      onTapDown: (_) => setState(() => _activeDirection = 'STOP'),
       onTapUp: (_) async {
  setState(() => _activeDirection = null);

  try {
    await widget.roverCommandService.stop();

    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ROVER STOPPED'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF5A1418),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bluetooth error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
},
      onTapCancel: () => setState(() => _activeDirection = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFB91C1C) : const Color(0xFF991B1B),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFEF4444),
            width: isActive ? 2.8 : 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: isActive ? 0.6 : 0.35),
              blurRadius: isActive ? 16 : 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pan_tool_rounded,
              size: 20,
              color: Colors.white,
            ),
            SizedBox(height: 2),
            Text(
              'STOP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. SPEED PANEL:
  /// - Compact rounded card
  /// - Title: SPEED
  /// - Horizontal speed selection slider
  /// - Cyan/blue selected portion
  /// - Local widget state
  Widget _buildSpeedPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: RoverColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: RoverColors.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Value Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.speed_rounded,
                    size: 16,
                    color: RoverColors.targetCyan,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'SPEED',
                    style: TextStyle(
                      color: RoverColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: RoverColors.targetCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: RoverColors.targetCyan.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  '${_speed.toInt()}%',
                  style: const TextStyle(
                    color: RoverColors.targetCyan,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
SliderTheme(
  data: SliderTheme.of(context).copyWith(
    activeTrackColor: RoverColors.targetCyan,
    inactiveTrackColor: const Color(0xFF0F172A),
    thumbColor: Colors.white,
    overlayColor: RoverColors.targetCyan.withValues(alpha: 0.2),
    trackHeight: 6.0,
    thumbShape: const RoundSliderThumbShape(
      enabledThumbRadius: 10.0,
    ),
    overlayShape: const RoundSliderOverlayShape(
      overlayRadius: 20.0,
    ),
  ),
  child: Slider(
    value: _speed,
    min: 0.0,
    max: 100.0,
    divisions: 10,
    onChanged: (val) {
      setState(() {
        _speed = val;
      });
    },
    onChangeEnd: (val) async {
      try {
        await widget.roverCommandService.setSpeed(
          val.toInt(),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bluetooth error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    },
  ),
),
          // Horizontal Slider with Cyan Accent 
          // Slider Labels
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0% (IDLE)',
                  style: TextStyle(
                    color: RoverColors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '100% (MAX)',
                  style: TextStyle(
                    color: RoverColors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4. OBSTACLE / ULTRASONIC CARD:
  /// Contains two smaller panels:
  /// Panel 1:
  /// - OBSTACLE (small gray uppercase text)
  /// - CLEAR (green)
  /// Panel 2:
  /// - ULTRASONIC (small gray uppercase text)
  /// - 167 cm (white text)
  Widget _buildObstacleUltrasonicCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RoverColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: RoverColors.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Panel 1: OBSTACLE -> CLEAR
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: RoverColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: RoverColors.cardBorder,
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 13,
                        color: RoverColors.radarGreen,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'OBSTACLE',
                        style: TextStyle(
                          color: RoverColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'CLEAR',
                    style: TextStyle(
                      color: RoverColors.radarGreen, // Green text
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Panel 2: ULTRASONIC -> 167 cm
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: RoverColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: RoverColors.cardBorder,
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.sensors_rounded,
                        size: 13,
                        color: RoverColors.targetCyan,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'ULTRASONIC',
                        style: TextStyle(
                          color: RoverColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '167 cm',
                    style: TextStyle(
                      color: Colors.white, // White text
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

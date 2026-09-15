import 'package:flutter/material.dart';
import '../models/radar_detection.dart';
import '../theme/rover_colors.dart';
import '../widgets/radar_scope.dart';
import '../widgets/rover_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTap;

  const HomeScreen({
    super.key,
    this.onNavTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Currently selected control mode (MANUAL by default)
  String _selectedMode = 'MANUAL';

  final List<String> _controlModes = const [
    'MANUAL',
    'ASSISTED',
    'FOLLOW ME',
    'AUTONOMOUS',
  ];

  // Static mock detections for Home Live Environment:
  // - 1 blue blip (target @ 5.83m, +41° matching telemetry panel)
  // - 2 yellow-orange blips (obstacles)
  // - 1 white central rover blip (built into RadarScope)
  final List<RadarDetection> _homeDetections = const [
    RadarDetection(
      id: 'target-blue',
      name: 'TARGET',
      distance: 5.83,
      bearing: 41,
      type: DetectionType.target,
      color: RoverColors.targetCyan, // Blue/cyan blip
    ),
    RadarDetection(
      id: 'obs-yellow-1',
      name: 'OBSTACLE 1',
      distance: 3.40,
      bearing: 145,
      type: DetectionType.obstacle,
      color: RoverColors.obstacleAmber, // Yellow-orange blip
    ),
    RadarDetection(
      id: 'obs-yellow-2',
      name: 'OBSTACLE 2',
      distance: 4.80,
      bearing: 280,
      type: DetectionType.obstacle,
      color: RoverColors.obstacleAmber, // Yellow-orange blip
    ),
  ];

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LIVE ENVIRONMENT Card
                    _buildLiveEnvironmentCard(),
                    const SizedBox(height: 16),

                    // DATA PANELS: DISTANCE, BEARING, CONFIDENCE
                    _buildDataPanels(),
                    const SizedBox(height: 18),

                    // CONTROL MODE Section
                    _buildControlModeSection(),
                    const SizedBox(height: 16),

                    // MISSION Card
                    _buildMissionCard(),
                    const SizedBox(height: 16),

                    // EMERGENCY STOP Button
                    _buildEmergencyStopButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar with Home (index 0) active
      bottomNavigationBar: RoverBottomNav(
        currentIndex: 0,
        onTap: widget.onNavTap,
      ),
    );
  }

  /// HEADER:
  /// - SMART ROVER
  /// - STM32F401 · HC-05
  /// - ONLINE with green dot
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
          // Title & Board / Module Subtitle
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SMART ROVER',
                style: TextStyle(
                  color: RoverColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'STM32F401 · HC-05',
                style: TextStyle(
                  color: RoverColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),

          // ONLINE status indicator with green dot
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
                    color: RoverColors.radarGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: RoverColors.radarGreen.withValues(alpha: 0.8),
                        blurRadius: 6,
                        spreadRadius: 1.5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'ONLINE',
                  style: TextStyle(
                    color: RoverColors.radarGreen,
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

  /// LIVE ENVIRONMENT card:
  /// - Title: LIVE ENVIRONMENT
  /// - Large circular radar
  /// - Concentric rings
  /// - 0°, 90°, 180°, 270°
  /// - Green radar sweep
  /// - 2 yellow-orange blips
  /// - 1 blue blip
  /// - 1 white central rover blip
  Widget _buildLiveEnvironmentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          // Card Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.radar_rounded,
                    size: 16,
                    color: RoverColors.radarGreen,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'LIVE ENVIRONMENT',
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RoverColors.radarGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ACTIVE FEED',
                  style: TextStyle(
                    color: RoverColors.radarGreen,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Radar Scope Widget with custom mock detections
          RadarScope(
            detections: _homeDetections,
            maxDistance: 8.0,
          ),
        ],
      ),
    );
  }

  /// DATA PANELS:
  /// - DISTANCE → 5.83 m
  /// - BEARING → +41°
  /// - CONFIDENCE → 67%
  Widget _buildDataPanels() {
    return Row(
      children: [
        // DISTANCE Card
        Expanded(
          child: _buildMetricTile(
            label: 'DISTANCE',
            value: '5.83',
            unit: 'm',
            icon: Icons.straighten_rounded,
            accentColor: RoverColors.targetCyan,
          ),
        ),
        const SizedBox(width: 10),

        // BEARING Card
        Expanded(
          child: _buildMetricTile(
            label: 'BEARING',
            value: '+41°',
            icon: Icons.explore_rounded,
            accentColor: RoverColors.radarGreen,
          ),
        ),
        const SizedBox(width: 10),

        // CONFIDENCE Card
        Expanded(
          child: _buildMetricTile(
            label: 'CONFIDENCE',
            value: '67%',
            icon: Icons.verified_user_rounded,
            accentColor: const Color(0xFF818CF8), // Soft indigo
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    String? unit,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: RoverColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: RoverColors.cardBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 13,
                color: accentColor,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: RoverColors.textSecondary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: RoverColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// CONTROL MODE:
  /// - MANUAL selected with ✓ and cyan-blue border/text
  /// - ASSISTED
  /// - FOLLOW ME
  /// - AUTONOMOUS
  Widget _buildControlModeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CONTROL MODE',
              style: TextStyle(
                color: RoverColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              'OPERATIONAL STATE',
              style: TextStyle(
                color: RoverColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 2x2 Grid of Control Mode Buttons
        Row(
          children: [
            Expanded(child: _buildModeButton(_controlModes[0])), // MANUAL
            const SizedBox(width: 10),
            Expanded(child: _buildModeButton(_controlModes[1])), // ASSISTED
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildModeButton(_controlModes[2])), // FOLLOW ME
            const SizedBox(width: 10),
            Expanded(child: _buildModeButton(_controlModes[3])), // AUTONOMOUS
          ],
        ),
      ],
    );
  }

  Widget _buildModeButton(String mode) {
    final bool isSelected = _selectedMode == mode;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? RoverColors.targetCyan.withValues(alpha: 0.12)
              : RoverColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? RoverColors.targetCyan : RoverColors.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: RoverColors.targetCyan.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check_rounded,
                size: 16,
                color: RoverColors.targetCyan,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              mode,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? RoverColors.targetCyan : RoverColors.textSecondary,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// MISSION CARD:
  /// - Section title: "MISSION"
  /// - Target area:
  ///   - Small gray uppercase label: "TARGET"
  ///   - Large bold white text: "YOU"
  /// - Divider line below target area
  /// - Key-value rows:
  ///   - DISTANCE: "6.16 m" (White text)
  ///   - BEARING: "+39°" (Cyan-blue text)
  ///   - CONFIDENCE: "70%" (Green text)
  /// - "APPROACHING" in bold mint-green text
  /// - Horizontal progress bar (dark background, solid mint green)
  Widget _buildMissionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
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
          // Section Title
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MISSION',
                style: TextStyle(
                  color: RoverColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                'ACTIVE TARGET LOCK',
                style: TextStyle(
                  color: RoverColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Target Area: Small gray label "TARGET", Large bold white text "YOU"
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TARGET',
                    style: TextStyle(
                      color: RoverColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'YOU',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: RoverColors.targetCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: RoverColors.targetCyan.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.my_location_rounded,
                      size: 13,
                      color: RoverColors.targetCyan,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'HOMING',
                      style: TextStyle(
                        color: RoverColors.targetCyan,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Divider Line below target area
          const Divider(
            color: RoverColors.cardBorder,
            thickness: 1.0,
            height: 1,
          ),
          const SizedBox(height: 14),

          // Key-Value Rows:
          // DISTANCE -> 6.16 m (White text)
          _buildMissionRow(
            label: 'DISTANCE',
            value: '6.16 m',
            valueColor: Colors.white,
          ),
          const SizedBox(height: 10),

          // BEARING -> +39° (Cyan-blue text)
          _buildMissionRow(
            label: 'BEARING',
            value: '+39°',
            valueColor: RoverColors.targetCyan,
          ),
          const SizedBox(height: 10),

          // CONFIDENCE -> 70% (Green text)
          _buildMissionRow(
            label: 'CONFIDENCE',
            value: '70%',
            valueColor: RoverColors.radarGreen,
          ),
          const SizedBox(height: 16),

          // Approach Status: "APPROACHING" in bold mint-green
          const Text(
            'APPROACHING',
            style: TextStyle(
              color: RoverColors.radarGreen,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Horizontal Progress Bar: Dark background, solid mint-green fill
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.70, // 70% progress matching confidence
              minHeight: 6,
              backgroundColor: Color(0xFF0A0F1D), // Dark background
              valueColor: AlwaysStoppedAnimation<Color>(RoverColors.radarGreen), // Solid mint green
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionRow({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: RoverColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  /// EMERGENCY STOP:
  /// - Full-width dark red emergency button
  /// - Rounded rectangular shape
  /// - Dark red background
  /// - Red border
  /// - Centered target/crosshair icon inside a circle
  /// - Bold red text: "EMERGENCY STOP"
  Widget _buildEmergencyStopButton() {
    return InkWell(
      onTap: () {
        // UI only for now - no Bluetooth/rover commands sent
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('EMERGENCY STOP ENGAGED (MOCK)'),
            duration: Duration(seconds: 1),
            backgroundColor: Color(0xFF5A1418),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C0B0E), // Dark red background
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFEF4444), // Red border
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Centered target/crosshair icon inside a circle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFEF4444),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.center_focus_strong_rounded,
                size: 16,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'EMERGENCY STOP',
              style: TextStyle(
                color: Color(0xFFEF4444), // Bold red text
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

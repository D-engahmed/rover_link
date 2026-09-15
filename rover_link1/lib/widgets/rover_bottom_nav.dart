import 'package:flutter/material.dart';
import '../theme/rover_colors.dart';

class RoverBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const RoverBottomNav({
    super.key,
    this.currentIndex = 2, // Radar selected by default
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = (currentIndex == 0 || currentIndex == 1)
        ? RoverColors.targetCyan
        : RoverColors.navActive;

    final navItems = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.sports_esports_rounded, label: 'Drive'),
      _NavItem(icon: Icons.radar_rounded, label: 'Radar'),
      _NavItem(icon: Icons.auto_awesome_rounded, label: 'AI'),
      _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: RoverColors.navBarBackground,
        border: const Border(
          top: BorderSide(
            color: RoverColors.navBarBorder,
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(navItems.length, (index) {
                  final isSelected = index == currentIndex;
                  final item = navItems[index];

                  return InkWell(
                    onTap: () => onTap?.call(index),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activeColor.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            size: 22,
                            color: isSelected
                                ? activeColor
                                : RoverColors.navInactive,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected
                                  ? activeColor
                                  : RoverColors.navInactive,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              // White horizontal gesture/navigation indicator bar
              Container(
                width: 42,
                height: 3.5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.label,
  });
}

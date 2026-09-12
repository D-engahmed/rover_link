import 'package:flutter/material.dart';

/// Central color palette, lifted directly from the CSS variables used in the
/// HTML prototype so the Flutter app and the prototype stay visually in sync.
class RoverColors {
  RoverColors._();

  static const bg = Color(0xFF05080C);
  static const panel = Color(0xFF0D141C);
  static const panel2 = Color(0xFF111B25);
  static const line = Color(0xFF243440);
  static const text = Color(0xFFE8F1F5);
  static const muted = Color(0xFF8296A3);
  static const cyan = Color(0xFF39D9FF);
  static const green = Color(0xFF55E6A5);
  static const amber = Color(0xFFFFBF5B);
  static const red = Color(0xFFFF5E67);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: RoverColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: RoverColors.cyan,
        secondary: RoverColors.green,
        error: RoverColors.red,
        surface: RoverColors.panel,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: RoverColors.bg,
        elevation: 0,
        foregroundColor: RoverColors.text,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: RoverColors.panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: RoverColors.line),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: RoverColors.text,
        displayColor: RoverColors.text,
      ),
      dividerColor: RoverColors.line,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: RoverColors.panel,
        selectedItemColor: RoverColors.cyan,
        unselectedItemColor: RoverColors.muted,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RoverColors.panel2,
          foregroundColor: RoverColors.text,
          side: const BorderSide(color: RoverColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  /// Reusable card decoration for panels that sit on the dashboard.
  static BoxDecoration panelDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: RoverColors.panel,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? RoverColors.line),
    );
  }
}

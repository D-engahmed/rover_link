import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class C {
  C._();
  // chrome
  static const chromeBg = Color(0xFF0A0D10);
  static const chromeLine = Color(0xFF1C242B);
  static const chromeText = Color(0xFFE7ECEF);
  static const chromeMuted = Color(0xFF71828C);
  static const stripOk = Color(0xFF0D1114);
  static const stripCaution = Color(0xFF161206);
  static const stripCrit = Color(0xFF1A0B0B);
  // semantic
  static const ok = Color(0xFF5EE08A);
  static const warn = Color(0xFFFFB100);
  static const crit = Color(0xFFFF4D4D);
  static const dangerBorder = Color(0xFF7A2020);
  static const dangerFill = Color(0xFF2A0D0D);
  static const dangerEdge = Color(0xFF5C1C1C);
  // terminal
  static const termBg = Color(0xFF060A05);
  static const termPanel = Color(0xFF0B1108);
  static const termLine = Color(0xFF1D2B14);
  static const amber = Color(0xFFFFB400);
  static const amberDim = Color(0xFF8A6A1C);
  static const grn = Color(0xFF7CFF6B);
  static const termText = Color(0xFFD9E4C8);
  static const termMuted = Color(0xFF5C6B4C);
  static const tsGreen = Color(0xFF3D4A30);
  static const padFill = Color(0xFF101A0A);
  // ai
  static const aiBg = Color(0xFF050B14);
  static const aiPanel = Color(0xFF0A1420);
  static const aiLine = Color(0xFF16324A);
  static const cyan = Color(0xFF57D6FF);
  static const cyanText = Color(0xFF001824);
  static const aiText = Color(0xFFDFF2FB);
  static const aiMuted = Color(0xFF4D7488);
  static const aiLogLine = Color(0xFFA9D8EC);
  static const tsBlue = Color(0xFF2C5470);
  static const gridBlue = Color(0xFF123045);
  static const gridDim = Color(0xFF0D2434);
}

class T {
  T._();
  static TextStyle mono(
    double s, {
    FontWeight w = FontWeight.w500,
    Color? c,
    double? h,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: s,
    fontWeight: w,
    color: c,
    height: h,
  );
  static TextStyle sans(double s, {FontWeight w = FontWeight.w500, Color? c}) =>
      GoogleFonts.spaceGrotesk(fontSize: s, fontWeight: w, color: c);
}

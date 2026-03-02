import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppGradients {
  // ── Aurora background (Home screen — Light) ──
  static const aurora = LinearGradient(
    begin: Alignment(-1, -1),
    end: Alignment(1, 1),
    colors: [
      AppColors.auroraLavender,
      AppColors.auroraBlue,
      AppColors.auroraSky,
      AppColors.auroraPink,
    ],
  );

  // ── Aurora background (Home screen — Dark) ──
  static const auroraDark = LinearGradient(
    begin: Alignment(-1, -1),
    end: Alignment(1, 1),
    colors: [
      AppColors.auroraDarkLavender,
      AppColors.auroraDarkBlue,
      AppColors.auroraDarkSky,
      AppColors.auroraDarkPink,
    ],
  );

  /// Returns the aurora gradient for the given brightness.
  static LinearGradient auroraFor(Brightness b) =>
      b == Brightness.dark ? auroraDark : aurora;

  // ── Primary to indigo (user chat bubble, buttons) ──
  static const primaryToIndigo = LinearGradient(
    colors: [AppColors.primary, Color(0xFF6366F1)],
  );

  // ── Text gradient (course title) ──
  static const textDark = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF475569)],
  );

  // ── Text gradient (Dark mode) ──
  static const textLight = LinearGradient(
    colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
  );

  /// Returns the text gradient for the given brightness.
  static LinearGradient textFor(Brightness b) =>
      b == Brightness.dark ? textLight : textDark;

  // ── Flashcard dark immersive background ──
  static const darkImmersive = RadialGradient(
    center: Alignment(0.0, -0.3),
    radius: 1.2,
    colors: [AppColors.surfaceDark, AppColors.backgroundDark],
  );

  // ── Exam event card gradient ──
  static const examPink = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.examPinkStart, AppColors.examPinkEnd],
  );

  // ── AI orb avatar ──
  static const orbAvatar = RadialGradient(
    center: Alignment(-0.3, -0.3),
    colors: [Color(0xFFA5A7FA), AppColors.primary],
  );

  // ── Subtle ethereal background (course detail, calendar — Light) ──
  static const ethereal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x26646FF2), // primary 15%
      Color(0x00FFFFFF),
      Color(0x1AEC4899), // pink 10%
      Color(0x00FFFFFF),
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  // ── Subtle ethereal background (Dark) ──
  static const etherealDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1A6467F2), // primary 10%
      Color(0x00000000),
      Color(0x10EC4899), // pink 6%
      Color(0x00000000),
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  /// Returns the ethereal gradient for the given brightness.
  static LinearGradient etherealFor(Brightness b) =>
      b == Brightness.dark ? etherealDark : ethereal;
}

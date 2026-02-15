import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppGradients {
  // ── Aurora background (Home screen) ──
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

  // ── Primary to indigo (user chat bubble, buttons) ──
  static const primaryToIndigo = LinearGradient(
    colors: [AppColors.primary, Color(0xFF6366F1)],
  );

  // ── Text gradient (course title) ──
  static const textDark = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF475569)],
  );

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

  // ── Subtle ethereal background (course detail, calendar) ──
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
}

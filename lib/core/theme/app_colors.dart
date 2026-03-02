import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Primary ──
  static const primary = Color(0xFF6467F2);
  static const primaryLight = Color(0xFF8A8CF7);
  static const primaryDark = Color(0xFF4F51C9);

  // ── Semantic ──
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);
  static const xpGold = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);

  // ── Surfaces (Light) ──
  static const backgroundLight = Color(0xFFF6F6F8);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const cardLight = Color(0xFFFFFFFF);

  // ── Surfaces (Dark) ──
  static const backgroundDark = Color(0xFF101122);
  static const surfaceDark = Color(0xFF2A2C4E);
  static const cardDark = Color(0xFF1A1B2E);

  // ── Glass (Light) ──
  static const glassWhite = Color(0x73FFFFFF); // 45%
  static const glassBorder = Color(0x33FFFFFF); // 20%
  static const glassHighlight = Color(0x0DFFFFFF); // 5%

  // ── Glass (Dark) ──
  static const glassDarkFill = Color(0x40FFFFFF); // 25%
  static const glassDarkBorder = Color(0x1AFFFFFF); // 10%
  static const glassDarkHighlight = Color(0x0AFFFFFF); // 4%

  // ── Text (Light) ──
  static const textPrimary = Color(0xFF1E293B); // slate-800
  static const textSecondary = Color(0xFF64748B); // slate-500
  static const textMuted = Color(0xFF94A3B8); // slate-400
  static const textOnPrimary = Color(0xFFFFFFFF);

  // ── Text (Dark) ──
  static const textPrimaryDark = Color(0xFFE2E8F0); // slate-200
  static const textSecondaryDark = Color(0xFF94A3B8); // slate-400
  static const textMutedDark = Color(0xFF64748B); // slate-500

  // ── Material type colors ──
  static const pdfRed = Color(0xFFEF4444);
  static const audioPurple = Color(0xFF8B5CF6);
  static const notesBlue = Color(0xFF3B82F6);
  static const scienceGreen = Color(0xFF10B981);

  // ── Aurora gradient stops (Light) ──
  static const auroraLavender = Color(0xFFE6E6FA);
  static const auroraBlue = Color(0xFFC5D8F7);
  static const auroraSky = Color(0xFFE0F2FE);
  static const auroraPink = Color(0xFFF3E8FF);

  // ── Aurora gradient stops (Dark) ──
  static const auroraDarkLavender = Color(0xFF1A1533);
  static const auroraDarkBlue = Color(0xFF131A2B);
  static const auroraDarkSky = Color(0xFF0F1A24);
  static const auroraDarkPink = Color(0xFF1A1228);

  // ── Exam card gradient ──
  static const examPinkStart = Color(0xFFFF9A9E);
  static const examPinkEnd = Color(0xFFFECFEF);

  // ── Adaptive helpers ──
  /// Returns the appropriate text primary color for the given brightness.
  static Color textPrimaryFor(Brightness b) =>
      b == Brightness.dark ? textPrimaryDark : textPrimary;

  static Color textSecondaryFor(Brightness b) =>
      b == Brightness.dark ? textSecondaryDark : textSecondary;

  static Color textMutedFor(Brightness b) =>
      b == Brightness.dark ? textMutedDark : textMuted;

  static Color backgroundFor(Brightness b) =>
      b == Brightness.dark ? backgroundDark : backgroundLight;

  static Color surfaceFor(Brightness b) =>
      b == Brightness.dark ? cardDark : surfaceLight;

  static Color cardFor(Brightness b) =>
      b == Brightness.dark ? cardDark : cardLight;
}

import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Primary ──
  static const primary = Color(0xFF6467F2);
  static const primaryLight = Color(0xFF8A8CF7);
  static const primaryDark = Color(0xFF4F51C9);

  // ── Semantic ──
  static const success = Color(0xFF34C759);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFFFCC00);

  // ── Surfaces ──
  static const backgroundLight = Color(0xFFF6F6F8);
  static const backgroundDark = Color(0xFF101122);
  static const surfaceDark = Color(0xFF2A2C4E);

  // ── Glass ──
  static const glassWhite = Color(0x73FFFFFF); // 45%
  static const glassBorder = Color(0x33FFFFFF); // 20%
  static const glassHighlight = Color(0x0DFFFFFF); // 5%

  // ── Text ──
  static const textPrimary = Color(0xFF1E293B); // slate-800
  static const textSecondary = Color(0xFF64748B); // slate-500
  static const textMuted = Color(0xFF94A3B8); // slate-400
  static const textOnPrimary = Color(0xFFFFFFFF);

  // ── Material type colors ──
  static const pdfRed = Color(0xFFEF4444);
  static const audioPurple = Color(0xFF8B5CF6);
  static const notesBlue = Color(0xFF3B82F6);
  static const scienceGreen = Color(0xFF10B981);

  // ── Aurora gradient stops ──
  static const auroraLavender = Color(0xFFE6E6FA);
  static const auroraBlue = Color(0xFFC5D8F7);
  static const auroraSky = Color(0xFFE0F2FE);
  static const auroraPink = Color(0xFFF3E8FF);

  // ── Exam card gradient ──
  static const examPinkStart = Color(0xFFFF9A9E);
  static const examPinkEnd = Color(0xFFFECFEF);
}

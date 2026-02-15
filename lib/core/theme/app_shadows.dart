import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppShadows {
  // ── Glass panel shadow ──
  static const glass = [
    BoxShadow(
      color: Color(0x1A6467F2), // primary 10%
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];

  // ── Elevated card shadow ──
  static const card = [
    BoxShadow(
      color: Color(0x0D000000), // black 5%
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];

  // ── Primary button glow ──
  static final primaryGlow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // ── Subtle shadow for small elements ──
  static const subtle = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  // ── Nav bar shadow ──
  static const navBar = [
    BoxShadow(
      color: Color(0x1A6467F2),
      blurRadius: 40,
      offset: Offset(0, -10),
    ),
  ];
}

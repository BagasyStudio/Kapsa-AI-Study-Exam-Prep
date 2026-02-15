import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  // ── Headings (Outfit) ──
  static const h1 = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const h2 = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static const h3 = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const h4 = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  // ── Body (Inter) ──
  static const bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // ── Labels (Inter Medium/SemiBold) ──
  static const labelLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const labelMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static const labelSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textMuted,
  );

  // ── Section headers (Inter - uppercase tracking) ──
  static const sectionHeader = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 1.2,
    color: AppColors.textMuted,
  );

  // ── Button (Inter) ──
  static const button = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textOnPrimary,
  );

  // ── Caption ──
  static const caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textMuted,
  );
}

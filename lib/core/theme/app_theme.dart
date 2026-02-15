import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.textOnPrimary,
          surface: AppColors.backgroundLight,
          onSurface: AppColors.textPrimary,
          error: AppColors.error,
        ),
        textTheme: TextTheme(
          displayLarge: AppTypography.h1,
          displayMedium: AppTypography.h2,
          displaySmall: AppTypography.h3,
          headlineMedium: AppTypography.h4,
          bodyLarge: AppTypography.bodyLarge,
          bodyMedium: AppTypography.bodyMedium,
          bodySmall: AppTypography.bodySmall,
          labelLarge: AppTypography.labelLarge,
          labelMedium: AppTypography.labelMedium,
          labelSmall: AppTypography.labelSmall,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          iconTheme: IconThemeData(color: AppColors.textSecondary),
          titleTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.primary,
          ),
        ),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
      );
}

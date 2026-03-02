import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_animations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/tap_scale.dart';
import '../widgets/pulse_glow.dart';

/// Custom floating bottom navigation matching the mockup design.
///
/// Layout: Home icon (left) — Capture pill (center) — Profile icon (right)
/// The Capture pill is a glass pill with camera icon + "Capture" text.
/// A bottom gradient fade sits behind everything for readability.
class KapsaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCaptureTap;

  const KapsaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCaptureTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Gradient fade color adapts to theme
    final fadeColor = isDark ? AppColors.backgroundDark : Colors.white;

    return SizedBox(
      height: 80 + bottomPadding,
      child: Stack(
        children: [
          // Bottom gradient fade for readability
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      fadeColor.withValues(alpha: 0.8),
                      fadeColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Navigation items
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding + AppSpacing.md,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Home icon
                  _NavIcon(
                    icon: Icons.home,
                    isSelected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),

                  // Courses icon
                  _NavIcon(
                    icon: Icons.menu_book,
                    isSelected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),

                  // Center: Capture pill with pulse glow
                  PulseGlow(
                    glowColor: AppColors.primary,
                    maxBlurRadius: 20,
                    duration: const Duration(milliseconds: 2500),
                    child: _CapturePill(onTap: onCaptureTap),
                  ),

                  // Calendar icon
                  _NavIcon(
                    icon: Icons.calendar_today,
                    isSelected: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),

                  // Profile icon
                  _NavIcon(
                    icon: Icons.person,
                    isSelected: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single nav icon button (Home or Profile).
class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      scaleDown: 0.88,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: AnimatedScale(
            scale: isSelected ? 1.08 : 1.0,
            duration: AppAnimations.durationMedium,
            curve: AppAnimations.curveBounce,
            child: AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.55,
              duration: AppAnimations.durationMedium,
              child: Icon(
                icon,
                size: 26,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textMutedFor(Theme.of(context).brightness),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The central Capture floating pill.
///
/// Glass pill with camera circle + "Capture" text.
/// Has a primary blur glow behind it.
class _CapturePill extends StatelessWidget {
  final VoidCallback onTap;

  const _CapturePill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillFillColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.45);
    final pillBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.5);
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return TapScale(
      onTap: onTap,
      scaleDown: 0.95,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Glow behind the pill
          Container(
            width: 130,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),

          // Glass pill
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: pillFillColor,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: pillBorderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Camera icon circle
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Capture',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

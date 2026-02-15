import 'package:flutter/material.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';

/// Pill-shaped segmented tab bar for course detail.
///
/// Tabs: Materials | Study Tools | Chat
class CourseTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<String> tabs;

  const CourseTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.tabs = const ['Materials', 'Study Tools', 'Chat'],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(right: index < tabs.length - 1 ? 10 : 0),
            child: GestureDetector(
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: AppAnimations.durationMedium,
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: AppRadius.borderRadiusPill,
                  border: isSelected
                      ? null
                      : Border.all(
                          color: const Color(0xFFE2E8F0),
                        ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tabs[index],
                  style: AppTypography.labelLarge.copyWith(
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

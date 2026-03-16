import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class KapsaRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const KapsaRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: const Color(0xFF1E1F3B),
      strokeWidth: 2.5,
      displacement: 50,
      child: child,
    );
  }
}

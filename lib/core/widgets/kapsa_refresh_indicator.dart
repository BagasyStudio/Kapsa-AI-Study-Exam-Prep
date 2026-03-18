import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_service.dart';
import '../theme/app_colors.dart';

class KapsaRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const KapsaRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  Future<void> _onRefreshWithHaptic() async {
    HapticFeedback.lightImpact();
    await onRefresh();
    HapticFeedback.mediumImpact();
    SoundService.playProcessingComplete();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefreshWithHaptic,
      color: AppColors.primary,
      backgroundColor: const Color(0xFF1E1F3B),
      strokeWidth: 2.5,
      displacement: 50,
      child: child,
    );
  }
}

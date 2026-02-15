import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/capture/presentation/screens/capture_sheet.dart';
import '../services/sound_service.dart';
import 'sanctuary_bottom_nav.dart';

/// Main scaffold that wraps the tab navigation.
///
/// Uses [StatefulNavigationShell] from GoRouter to maintain tab state.
/// The bottom navigation bar and Capture FAB overlay on top of content.
class KapsaShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const KapsaShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: navigationShell,
      bottomNavigationBar: KapsaBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          if (index != navigationShell.currentIndex) {
            SoundService.playTabSwitch();
          }
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        onCaptureTap: () => _showCaptureSheet(context),
      ),
    );
  }

  void _showCaptureSheet(BuildContext context) async {
    SoundService.playCaptureStart();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => const CaptureSheet(),
    );
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }
}

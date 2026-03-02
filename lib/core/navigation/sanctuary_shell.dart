import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/capture/presentation/screens/capture_sheet.dart';
import '../services/sound_service.dart';
import 'sanctuary_bottom_nav.dart';

/// Main scaffold that wraps the tab navigation.
///
/// Uses [StatefulNavigationShell] from GoRouter to maintain tab state.
/// The bottom navigation bar and Capture FAB overlay on top of content.
class KapsaShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const KapsaShell({super.key, required this.navigationShell});

  @override
  State<KapsaShell> createState() => _KapsaShellState();
}

class _KapsaShellState extends State<KapsaShell>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: widget.navigationShell,
      bottomNavigationBar: KapsaBottomNav(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (index) {
          if (index != widget.navigationShell.currentIndex) {
            SoundService.playTabSwitch();
          }
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
        onCaptureTap: () => _showCaptureSheet(context),
      ),
    );
  }

  void _showCaptureSheet(BuildContext context) async {
    SoundService.playCaptureStart();

    // Spring-like animation controller for the bottom sheet entrance.
    // Uses a slightly longer duration with an easeOutBack curve to give
    // a subtle bounce / spring feel when the sheet appears.
    final animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      reverseDuration: const Duration(milliseconds: 300),
    );

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionAnimationController: animController,
      builder: (_) => const CaptureSheet(),
    );

    animController.dispose();

    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }
}

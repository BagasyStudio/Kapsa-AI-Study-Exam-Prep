import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/capture/presentation/screens/capture_sheet.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../services/sound_service.dart';
import 'sanctuary_bottom_nav.dart';

/// Main scaffold that wraps the tab navigation.
///
/// Uses [StatefulNavigationShell] from GoRouter to maintain tab state.
/// The bottom navigation bar and Capture FAB overlay on top of content.
///
/// Also acts as an [AppLifecycleState] observer: when the app resumes from
/// background, it refreshes the Supabase auth session to prevent
/// "session expired" errors after extended periods in the background.
class KapsaShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const KapsaShell({super.key, required this.navigationShell});

  @override
  ConsumerState<KapsaShell> createState() => _KapsaShellState();
}

class _KapsaShellState extends ConsumerState<KapsaShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshSessionOnResume();
    }
  }

  /// Silently refresh the auth session when the app returns to foreground.
  ///
  /// This prevents stale JWTs from causing "session expired" errors.
  /// Also invalidates the profile provider so any changes (e.g. streak)
  /// are reflected when the user returns.
  Future<void> _refreshSessionOnResume() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;

      // Only refresh if the token is close to expiring (within 5 min)
      final expiresAt = session.expiresAt;
      if (expiresAt != null) {
        final expiresDate =
            DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
        final remaining = expiresDate.difference(DateTime.now());
        if (remaining.inMinutes > 5) return; // Still fresh
      }

      await Supabase.instance.client.auth.refreshSession();
      ref.invalidate(profileProvider);
    } catch (_) {
      // Best-effort — don't crash the app
    }
  }

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

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, __) => const CaptureSheet(),
      ),
    );

    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }
}

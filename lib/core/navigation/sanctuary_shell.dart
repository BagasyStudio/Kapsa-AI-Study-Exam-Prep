import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/capture/presentation/screens/capture_sheet.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../services/sound_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
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
  static const _fabFirstUsedKey = 'fab_first_used';

  /// Whether the pulsing glow on the Capture FAB should be shown.
  bool _showPulseGlow = false;

  /// Timestamp when the app was last paused (sent to background).
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFabGlowState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Load whether the FAB has been used before from SharedPreferences.
  Future<void> _loadFabGlowState() async {
    final prefs = await SharedPreferences.getInstance();
    final hasBeenUsed = prefs.getBool(_fabFirstUsedKey) ?? false;
    if (mounted) {
      setState(() {
        _showPulseGlow = !hasBeenUsed;
      });
    }
  }

  /// Mark the FAB as used and stop the glow permanently.
  Future<void> _markFabUsed() async {
    if (!_showPulseGlow) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fabFirstUsedKey, true);
    if (mounted) {
      setState(() {
        _showPulseGlow = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _refreshSessionOnResume();
      _showWelcomeBackToastIfNeeded();
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

  /// Show a subtle "Synced" toast if the app was in the background
  /// for more than 30 seconds.
  void _showWelcomeBackToastIfNeeded() {
    final pausedAt = _pausedAt;
    if (pausedAt == null) return;

    final elapsed = DateTime.now().difference(pausedAt);
    if (elapsed.inSeconds <= 30) return;

    _pausedAt = null;

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '\u2713 Synced',
          style: AppTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        elevation: 0,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 120,
          left: 80,
          right: 80,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Handle long-press on the Capture FAB: show a tooltip snackbar with
  /// haptic feedback.
  void _onCaptureLongPress() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Upload materials to start studying',
          style: AppTypography.bodySmall.copyWith(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.immersiveSurface,
        margin: const EdgeInsets.only(bottom: 100, left: 40, right: 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey<int>(widget.navigationShell.currentIndex),
          child: widget.navigationShell,
        ),
      ),
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
        onCaptureTap: () {
          _markFabUsed();
          _showCaptureSheet(context);
        },
        onCaptureLongPress: _onCaptureLongPress,
        showPulseGlow: _showPulseGlow,
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

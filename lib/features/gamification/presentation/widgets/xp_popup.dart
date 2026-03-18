import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';

/// Animated "+X XP" toast overlay with queue-based anti-overlap and combo support.
///
/// - Each popup waits for the previous one to finish (or staggers by 500ms).
/// - If 3+ popups fire within 10 seconds, they merge into a single "+N XP COMBO!" popup.
/// - Uses a static queue to serialize pending popups.
/// Use [XpPopup.show] to display a floating XP notification.
class XpPopup {
  XpPopup._();

  static OverlayState? _overlayState;
  static final List<_XpPopupEntry> _activeEntries = [];

  // Queue for serializing popup display
  static final Queue<_XpQueueItem> _queue = Queue();
  static bool _isProcessing = false;

  // Combo tracking
  static final List<_XpEvent> _recentEvents = [];
  static Timer? _comboTimer;

  /// Combo detection window: 10 seconds.
  static const _comboWindowMs = 10000;

  /// Stagger delay between queued popups: 500ms.
  static const _staggerMs = 500;

  /// Show a floating "+X XP" popup at the top of the screen.
  ///
  /// Popups are queued so each one waits for the previous to finish
  /// (staggered by 500ms). If 3+ popups arrive within 10 seconds,
  /// they are combined into a single combo popup.
  static void show(BuildContext context, {required int xp, String? label}) {
    _overlayState = Overlay.of(context);

    // Record this event for combo detection
    final now = DateTime.now();
    _recentEvents.add(_XpEvent(xp: xp, label: label, time: now));

    // Clean old events (older than 10 seconds)
    _recentEvents.removeWhere(
      (e) => now.difference(e.time).inMilliseconds > _comboWindowMs,
    );

    // Check combo: 3+ events within 10 seconds
    if (_recentEvents.length >= 3) {
      _triggerCombo(context);
      return;
    }

    // Reset combo timer
    _comboTimer?.cancel();
    _comboTimer = Timer(const Duration(milliseconds: _comboWindowMs), () {
      _recentEvents.clear();
    });

    // Enqueue instead of showing immediately
    _enqueue(context, xp: xp, label: label);
  }

  static void _triggerCombo(BuildContext context) {
    // Sum all recent XP
    final totalXp = _recentEvents.fold<int>(0, (sum, e) => sum + e.xp);

    // Dismiss all active popups
    for (final entry in List.of(_activeEntries)) {
      entry.dismiss();
    }
    _activeEntries.clear();

    // Clear queue, events and timer
    _queue.clear();
    _isProcessing = false;
    _recentEvents.clear();
    _comboTimer?.cancel();
    _comboTimer = null;

    // Show combo popup immediately (bypasses queue)
    _showSingle(
      totalXp,
      label: 'XP COMBO!',
      isCombo: true,
    );
  }

  /// Adds a popup to the queue and starts processing if idle.
  static void _enqueue(BuildContext context, {required int xp, String? label}) {
    _queue.add(_XpQueueItem(xp: xp, label: label));
    _processQueue();
  }

  /// Processes the queue one popup at a time with 500ms stagger delay.
  static void _processQueue() {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    final item = _queue.removeFirst();

    // Brief delay before showing so rapid calls get staggered
    final delay = _activeEntries.isNotEmpty
        ? const Duration(milliseconds: _staggerMs)
        : Duration.zero;

    void showItem() {
      // Guard: overlay may have been disposed while waiting
      if (_overlayState == null) {
        _isProcessing = false;
        return;
      }
      _showSingle(
        item.xp,
        label: item.label,
        onFinished: () {
          _isProcessing = false;
          _processQueue();
        },
      );
    }

    if (delay > Duration.zero) {
      Future.delayed(delay, showItem);
    } else {
      showItem();
    }
  }

  static void _showSingle(
    int xp, {
    String? label,
    bool isCombo = false,
    VoidCallback? onFinished,
  }) {
    final overlay = _overlayState;
    if (overlay == null) {
      onFinished?.call();
      return;
    }

    // Calculate stack index: count still-visible entries
    final stackIndex = _activeEntries.length;

    late OverlayEntry overlayEntry;
    late _XpPopupEntry popupEntry;

    overlayEntry = OverlayEntry(
      builder: (ctx) => _XpPopupWidget(
        xp: xp,
        label: label,
        isCombo: isCombo,
        stackIndex: stackIndex,
        onDismiss: () {
          overlayEntry.remove();
          _activeEntries.remove(popupEntry);
          // Notify queue that this popup is done
          onFinished?.call();
        },
        onRequestDismiss: (callback) {
          popupEntry._dismissCallback = callback;
        },
      ),
    );

    popupEntry = _XpPopupEntry(overlayEntry: overlayEntry);
    _activeEntries.add(popupEntry);
    overlay.insert(overlayEntry);
  }
}

// ── Internal helpers ───────────────────────────────────────────────────────

class _XpEvent {
  final int xp;
  final String? label;
  final DateTime time;

  _XpEvent({required this.xp, this.label, required this.time});
}

class _XpQueueItem {
  final int xp;
  final String? label;

  _XpQueueItem({required this.xp, this.label});
}

class _XpPopupEntry {
  final OverlayEntry overlayEntry;
  VoidCallback? _dismissCallback;

  _XpPopupEntry({required this.overlayEntry});

  void dismiss() {
    _dismissCallback?.call();
  }
}

// ── Widget ─────────────────────────────────────────────────────────────────

class _XpPopupWidget extends StatefulWidget {
  final int xp;
  final String? label;
  final bool isCombo;
  final int stackIndex;
  final VoidCallback onDismiss;
  final void Function(VoidCallback) onRequestDismiss;

  const _XpPopupWidget({
    required this.xp,
    this.label,
    required this.isCombo,
    required this.stackIndex,
    required this.onDismiss,
    required this.onRequestDismiss,
  });

  @override
  State<_XpPopupWidget> createState() => _XpPopupWidgetState();
}

class _XpPopupWidgetState extends State<_XpPopupWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.isCombo ? 2400 : 1800,
      ),
    );

    _scaleAnim = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: widget.isCombo ? 1.3 : 1.2)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.isCombo ? 1.3 : 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.8)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_controller);

    // Fade in quickly, hold, then fade out smoothly
    _opacityAnim = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_controller);

    // Slide upward and fade out (enter from below, exit above)
    _slideAnim = TweenSequence<Offset>([
      // Enter: slide up from 0.3 to 0.0
      TweenSequenceItem(
        tween: Tween(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 20,
      ),
      // Hold in place
      TweenSequenceItem(
        tween: ConstantTween(Offset.zero),
        weight: 50,
      ),
      // Exit: slide up and out
      TweenSequenceItem(
        tween: Tween(
          begin: Offset.zero,
          end: const Offset(0, -0.5),
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_controller);

    // Register dismiss callback so the manager can force-dismiss this popup
    widget.onRequestDismiss(_forceDismiss);

    // Start immediately — stagger delay is handled by the queue
    _start();
  }

  void _start() {
    if (!mounted) return;
    _controller.forward().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  void _forceDismiss() {
    if (!mounted) return;
    // Fast fade out
    _controller.animateTo(
      1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeIn,
    ).then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    // Stack offset: each popup is 48px below the previous one
    final verticalOffset = topPadding + 60 + (widget.stackIndex * 48.0);

    return Positioned(
      top: verticalOffset,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _opacityAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isCombo ? 24 : 20,
                  vertical: widget.isCombo ? 12 : 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isCombo
                        ? const [Color(0xFFEF4444), Color(0xFFF97316)]
                        : const [Color(0xFFF59E0B), Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isCombo
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFF59E0B))
                          .withValues(alpha: 0.4),
                      blurRadius: widget.isCombo ? 28 : 20,
                      offset: const Offset(0, 4),
                    ),
                    if (widget.isCombo)
                      BoxShadow(
                        color:
                            const Color(0xFFFFD700).withValues(alpha: 0.3),
                        blurRadius: 40,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isCombo ? Icons.whatshot : Icons.bolt,
                      color: Colors.white,
                      size: widget.isCombo ? 24 : 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+${widget.xp} XP',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: widget.isCombo ? 18 : 16,
                      ),
                    ),
                    if (widget.label != null || widget.isCombo) ...[
                      const SizedBox(width: 8),
                      Text(
                        widget.label ?? '',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                          fontSize: widget.isCombo ? 13 : 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

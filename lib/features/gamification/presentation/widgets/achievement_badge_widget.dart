import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/achievement_model.dart';

/// Returns the border color for a rarity tier.
Color _rarityBorderColor(BadgeRarity rarity) {
  return switch (rarity) {
    BadgeRarity.common => const Color(0xFF6B7280), // grey
    BadgeRarity.rare => const Color(0xFF3B82F6), // blue
    BadgeRarity.epic => const Color(0xFF8B5CF6), // purple
    BadgeRarity.legendary => const Color(0xFFF59E0B), // gold
  };
}

/// Returns the glow color for a rarity tier (null for common).
Color? _rarityGlowColor(BadgeRarity rarity) {
  return switch (rarity) {
    BadgeRarity.common => null,
    BadgeRarity.rare => const Color(0xFF3B82F6),
    BadgeRarity.epic => const Color(0xFF8B5CF6),
    BadgeRarity.legendary => const Color(0xFFF59E0B),
  };
}

/// Returns the rarity label text.
String _rarityLabel(BadgeRarity rarity) {
  return switch (rarity) {
    BadgeRarity.common => 'Common',
    BadgeRarity.rare => 'Rare',
    BadgeRarity.epic => 'Epic',
    BadgeRarity.legendary => 'Legendary',
  };
}

/// A single achievement badge icon with title.
///
/// Shows rarity-based borders and glow effects for unlocked badges.
/// Locked badges display a grayscale filter with a lock overlay.
/// Tapping a locked badge triggers a shake animation and tooltip.
/// Recently unlocked badges show a pulsing "NEW" indicator.
/// Forced immersive dark styling.
class AchievementBadgeWidget extends StatefulWidget {
  final BadgeDefinition badge;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int? currentProgress;
  final int? targetProgress;
  final VoidCallback? onTap;

  const AchievementBadgeWidget({
    super.key,
    required this.badge,
    this.isUnlocked = false,
    this.unlockedAt,
    this.currentProgress,
    this.targetProgress,
    this.onTap,
  });

  @override
  State<AchievementBadgeWidget> createState() =>
      _AchievementBadgeWidgetState();
}

class _AchievementBadgeWidgetState extends State<AchievementBadgeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  /// Whether the badge was unlocked within the last 3 days.
  bool get _isRecentlyUnlocked {
    if (!widget.isUnlocked || widget.unlockedAt == null) return false;
    return DateTime.now().difference(widget.unlockedAt!).inDays < 3;
  }

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    // 2 quick left-right oscillations over 200ms (2 full sine cycles)
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onLockedTap() {
    HapticFeedback.lightImpact();
    _shakeController.forward(from: 0);

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _LockedBadgeTooltip(
        position: offset,
        parentSize: size,
        description: widget.badge.description,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ??
          (widget.isUnlocked
              ? () => _showDetail(context)
              : _onLockedTap),
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          // 2 full sine cycles => 4*pi over 0..1
          final shakeOffset = widget.isUnlocked
              ? 0.0
              : math.sin(_shakeAnimation.value * 4 * math.pi) * 3.0;
          return Transform.translate(
            offset: Offset(shakeOffset, 0),
            child: child,
          );
        },
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge circle with rarity effects
              Stack(
                clipBehavior: Clip.none,
                children: [
                  if (widget.isUnlocked &&
                      widget.badge.rarity == BadgeRarity.legendary)
                    _LegendaryShimmer(
                      child: _buildBadgeCircle(),
                    )
                  else
                    _buildBadgeCircle(),

                  // "NEW" pulsing badge
                  if (_isRecentlyUnlocked)
                    const Positioned(
                      top: -4,
                      right: -4,
                      child: _PulsingNewBadge(),
                    ),

                  // Lock icon overlay for locked badges
                  if (!widget.isUnlocked)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1A1B2E),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock_rounded,
                            size: 10,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Title
              Text(
                widget.badge.title,
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  fontWeight:
                      widget.isUnlocked ? FontWeight.w600 : FontWeight.w400,
                  color: widget.isUnlocked
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.25),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeCircle() {
    final rarityBorder = _rarityBorderColor(widget.badge.rarity);
    final rarityGlow = _rarityGlowColor(widget.badge.rarity);

    final circle = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: widget.isUnlocked
            ? LinearGradient(
                colors: widget.badge.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: widget.isUnlocked ? null : Colors.white.withValues(alpha: 0.06),
        border: widget.isUnlocked
            ? Border.all(
                color: rarityBorder.withValues(alpha: 0.7),
                width: widget.badge.rarity == BadgeRarity.legendary
                    ? 2.0
                    : 1.5,
              )
            : Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.0,
              ),
        boxShadow: widget.isUnlocked
            ? [
                BoxShadow(
                  color: widget.badge.gradient.first
                      .withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                if (rarityGlow != null)
                  BoxShadow(
                    color: rarityGlow.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
              ]
            : null,
      ),
      child: Icon(
        widget.badge.icon,
        size: 26,
        color: widget.isUnlocked
            ? Colors.white
            : Colors.white.withValues(alpha: 0.18),
      ),
    );

    // Apply grayscale filter for locked badges
    if (!widget.isUnlocked) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: circle,
      );
    }

    return circle;
  }

  void _showDetail(BuildContext context) {
    final rarityColor = _rarityBorderColor(widget.badge.rarity);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.immersiveCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Large badge
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.isUnlocked
                    ? LinearGradient(
                        colors: widget.badge.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: widget.isUnlocked
                    ? null
                    : Colors.white.withValues(alpha: 0.08),
                border: widget.isUnlocked
                    ? Border.all(
                        color: rarityColor.withValues(alpha: 0.6),
                        width: 2,
                      )
                    : null,
                boxShadow: widget.isUnlocked
                    ? [
                        BoxShadow(
                          color: widget.badge.gradient.first
                              .withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                widget.badge.icon,
                size: 38,
                color: widget.isUnlocked
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.25),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.badge.title,
              style: AppTypography.h3.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            // Rarity label
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: rarityColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: rarityColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _rarityLabel(widget.badge.rarity),
                style: AppTypography.caption.copyWith(
                  color: rarityColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.badge.description,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.isUnlocked && widget.unlockedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Unlocked on ${_formatDate(widget.unlockedAt!)}',
                style: AppTypography.caption.copyWith(
                  color: widget.badge.gradient.first,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (!widget.isUnlocked) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  widget.currentProgress != null &&
                          widget.targetProgress != null
                      ? 'Progress: ${widget.currentProgress}/${widget.targetProgress}'
                      : 'Locked',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Pulsing "NEW" badge for recently unlocked achievements
// ═══════════════════════════════════════════════════════════════════════════════

class _PulsingNewBadge extends StatefulWidget {
  const _PulsingNewBadge();

  @override
  State<_PulsingNewBadge> createState() => _PulsingNewBadgeState();
}

class _PulsingNewBadgeState extends State<_PulsingNewBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.5),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
        ),
        child: const Text(
          'NEW',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 7,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Legendary shimmer effect wrapper
// ═══════════════════════════════════════════════════════════════════════════════

class _LegendaryShimmer extends StatefulWidget {
  final Widget child;

  const _LegendaryShimmer({required this.child});

  @override
  State<_LegendaryShimmer> createState() => _LegendaryShimmerState();
}

class _LegendaryShimmerState extends State<_LegendaryShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            widget.child,
            // Shimmer sweep overlay
            Positioned.fill(
              child: ClipOval(
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    final progress = _controller.value;
                    return LinearGradient(
                      begin: Alignment(-1.0 + 3.0 * progress, -0.3),
                      end: Alignment(-0.5 + 3.0 * progress, 0.3),
                      colors: [
                        Colors.transparent,
                        const Color(0xFFF59E0B).withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcATop,
                  child: Container(
                    width: 56,
                    height: 56,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tooltip overlay for locked badges
// ═══════════════════════════════════════════════════════════════════════════════

class _LockedBadgeTooltip extends StatefulWidget {
  final Offset position;
  final Size parentSize;
  final String description;
  final VoidCallback onDismiss;

  const _LockedBadgeTooltip({
    required this.position,
    required this.parentSize,
    required this.description,
    required this.onDismiss,
  });

  @override
  State<_LockedBadgeTooltip> createState() => _LockedBadgeTooltipState();
}

class _LockedBadgeTooltipState extends State<_LockedBadgeTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..forward();
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _fadeController.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const tooltipWidth = 180.0;
    // Center tooltip horizontally on the badge
    double left =
        widget.position.dx + widget.parentSize.width / 2 - tooltipWidth / 2;
    // Clamp so it stays on-screen
    left = left.clamp(8.0, screenWidth - tooltipWidth - 8.0);
    // Place above the badge
    final top = widget.position.dy - 44;

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: GestureDetector(
            onTap: () {
              _fadeController.reverse().then((_) => widget.onDismiss());
            },
            child: Container(
              width: tooltipWidth,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2B45),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    size: 12,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.description,
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

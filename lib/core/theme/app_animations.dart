import 'package:flutter/animation.dart';

/// Centralized animation constants for Kapsa.
///
/// Single source of truth for all durations, curves, and stagger values.
/// Follows the same `abstract final class` pattern as [AppColors], [AppSpacing].
abstract final class AppAnimations {
  // ── Durations ──

  /// Micro-interaction: button press, icon toggle (150ms)
  static const durationFast = Duration(milliseconds: 150);

  /// Standard: tab switch, card state change, nav indicator (250ms)
  static const durationMedium = Duration(milliseconds: 250);

  /// Emphasis: page transition, card flip, modal (350ms)
  static const durationSlow = Duration(milliseconds: 350);

  /// Entrance: staggered list items appearing (500ms)
  static const durationEntrance = Duration(milliseconds: 500);

  /// Long: score ring fill, progress animation (800ms)
  static const durationLong = Duration(milliseconds: 800);

  /// Ambient: breathing pulse, orb drift (3s)
  static const durationBreathing = Duration(seconds: 3);

  // ── Curves ──

  /// Default for most transitions — smooth deceleration
  static const curveStandard = Curves.easeOutCubic;

  /// Snappy bounce for tap feedback — slight overshoot on release
  static const curveBounce = Curves.easeOutBack;

  /// For entrance animations — items sliding in with strong deceleration
  static const curveEntrance = Curves.easeOutQuart;

  /// For progress fills — dramatic deceleration at end
  static const curveDecelerate = Curves.easeOutCirc;

  // ── Stagger ──

  /// Delay between items in a staggered list entrance
  static const staggerInterval = Duration(milliseconds: 60);

  /// Items beyond this index appear instantly (no more stagger)
  static const maxStaggerItems = 8;
}

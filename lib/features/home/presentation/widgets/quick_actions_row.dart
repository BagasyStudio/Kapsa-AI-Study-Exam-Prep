import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';

// ---------------------------------------------------------------------------
// Quick Actions Row — Premium Custom-Painted Icons
// ---------------------------------------------------------------------------

/// Quick action buttons row on the home screen.
/// 4 gradient circles with custom-painted icons, glass shine overlay,
/// animated glow pulse, and staggered entrance animation.
///
/// [badges] is an optional map of action index -> count. When provided,
/// a red notification badge is shown on the corresponding action circle.
class QuickActionsRow extends StatefulWidget {
  final Map<int, int>? badges;

  const QuickActionsRow({super.key, this.badges});

  @override
  State<QuickActionsRow> createState() => _QuickActionsRowState();
}

class _QuickActionsRowState extends State<QuickActionsRow>
    with TickerProviderStateMixin {
  late List<AnimationController> _entranceControllers;
  late List<Animation<double>> _scaleAnims;
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  static final _actions = [
    _ActionData(
      painterBuilder: (color) => _SnapSolveIconPainter(color: color),
      label: 'Snap Solve',
      colors: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
      shadowColor: const Color(0xFFF59E0B),
    ),
    _ActionData(
      painterBuilder: (color) => _OracleIconPainter(color: color),
      label: 'Oracle',
      colors: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
      shadowColor: const Color(0xFF8B5CF6),
    ),
    _ActionData(
      painterBuilder: (color) => _GroupsIconPainter(color: color),
      label: 'Groups',
      colors: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
      shadowColor: const Color(0xFF3B82F6),
    ),
    _ActionData(
      painterBuilder: (color) => _ExamIconPainter(color: color),
      label: 'Exam',
      colors: const [Color(0xFF10B981), Color(0xFF34D399)],
      shadowColor: const Color(0xFF10B981),
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Staggered entrance controllers
    _entranceControllers = List.generate(4, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
    });
    _scaleAnims = _entranceControllers.map((c) {
      return CurvedAnimation(parent: c, curve: Curves.elasticOut);
    }).toList();

    for (int i = 0; i < 4; i++) {
      Future.delayed(Duration(milliseconds: 80 * i), () {
        if (mounted) _entranceControllers[i].forward();
      });
    }

    // Shared glow pulse controller
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.20, end: 0.40).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    for (final c in _entranceControllers) {
      c.dispose();
    }
    _glowController.dispose();
    super.dispose();
  }

  void _onTap(int index, BuildContext context) {
    HapticFeedback.lightImpact();
    switch (index) {
      case 0:
        context.push(Routes.snapSolve);
      case 1:
        context.push(Routes.oracle);
      case 2:
        context.push(Routes.groupsList);
      case 3:
        context.push(Routes.practiceExam);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (i) {
          final badgeCount = widget.badges?[i];
          return ScaleTransition(
            scale: _scaleAnims[i],
            child: _GradientAction(
              data: _actions[i],
              onTap: () => _onTap(i, context),
              glowAnim: _glowAnim,
              badgeCount: badgeCount != null && badgeCount > 0
                  ? badgeCount
                  : null,
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action Data Model
// ---------------------------------------------------------------------------

class _ActionData {
  final CustomPainter Function(Color color) painterBuilder;
  final String label;
  final List<Color> colors;
  final Color shadowColor;

  _ActionData({
    required this.painterBuilder,
    required this.label,
    required this.colors,
    required this.shadowColor,
  });
}

// ---------------------------------------------------------------------------
// Gradient Action Button
// ---------------------------------------------------------------------------

class _GradientAction extends AnimatedWidget {
  final _ActionData data;
  final VoidCallback onTap;
  final int? badgeCount;

  const _GradientAction({
    required this.data,
    required this.onTap,
    required Animation<double> glowAnim,
    this.badgeCount,
  }) : super(listenable: glowAnim);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final glowAlpha = (listenable as Animation<double>).value;

    return TapScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Main circle
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color.lerp(data.colors[1], Colors.white, 0.15)!,
                      data.colors[0],
                      Color.lerp(data.colors[0], Colors.black, 0.10)!,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                    center: const Alignment(-0.3, -0.3),
                    radius: 0.9,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: data.shadowColor.withValues(alpha: glowAlpha),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glass shine crescent overlay
                    CustomPaint(
                      size: const Size(58, 58),
                      painter: _GlassShinePainter(),
                    ),
                    // Custom icon
                    CustomPaint(
                      size: const Size(26, 26),
                      painter: data.painterBuilder(Colors.white),
                    ),
                  ],
                ),
              ),
              // Badge
              if (badgeCount != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: _NotificationBadge(count: badgeCount!),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryFor(brightness),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Glass Shine Overlay
// ---------------------------------------------------------------------------

/// Paints a subtle crescent highlight at the top of the circle
/// to simulate a glassy, 3D-reflective surface.
class _GlassShinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Crescent highlight: arc clipped to upper-left quadrant
    final shinePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.clipPath(shinePath);

    final shineRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.55);
    final shinePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.3, 0),
        Offset(size.width * 0.3, size.height * 0.55),
        [
          Colors.white.withValues(alpha: 0.22),
          Colors.white.withValues(alpha: 0.0),
        ],
      );
    canvas.drawOval(shineRect, shinePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlassShinePainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Custom Icon Painters
// ---------------------------------------------------------------------------

/// Snap Solve: Camera lens with viewfinder corners and focus dot.
class _SnapSolveIconPainter extends CustomPainter {
  final Color color;
  const _SnapSolveIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final unit = size.width; // 26 logical px

    // Outer lens circle
    final lensPaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(Offset(cx, cy), unit * 0.32, lensPaint);

    // Inner sensor circle (filled, semi-transparent)
    final sensorPaint = Paint()
      ..color = color.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), unit * 0.18, sensorPaint);

    // Focus dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), unit * 0.06, dotPaint);

    // Viewfinder corner brackets
    final cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final m = unit * 0.08; // margin from edge
    final arm = unit * 0.22; // bracket arm length

    // Top-left
    canvas.drawLine(Offset(m, m + arm), Offset(m, m), cornerPaint);
    canvas.drawLine(Offset(m, m), Offset(m + arm, m), cornerPaint);

    // Top-right
    canvas.drawLine(
        Offset(unit - m - arm, m), Offset(unit - m, m), cornerPaint);
    canvas.drawLine(
        Offset(unit - m, m), Offset(unit - m, m + arm), cornerPaint);

    // Bottom-left
    canvas.drawLine(
        Offset(m, unit - m - arm), Offset(m, unit - m), cornerPaint);
    canvas.drawLine(
        Offset(m, unit - m), Offset(m + arm, unit - m), cornerPaint);

    // Bottom-right
    canvas.drawLine(Offset(unit - m - arm, unit - m),
        Offset(unit - m, unit - m), cornerPaint);
    canvas.drawLine(Offset(unit - m, unit - m),
        Offset(unit - m, unit - m - arm), cornerPaint);
  }

  @override
  bool shouldRepaint(_SnapSolveIconPainter old) => old.color != color;
}

/// Oracle: Faceted diamond/crystal with sparkle accents.
class _OracleIconPainter extends CustomPainter {
  final Color color;
  const _OracleIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final unit = size.width;

    // Diamond shape
    final diamondPath = Path()
      ..moveTo(cx, unit * 0.08) // top
      ..lineTo(unit * 0.88, cy) // right
      ..lineTo(cx, unit * 0.92) // bottom
      ..lineTo(unit * 0.12, cy) // left
      ..close();

    // Fill
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawPath(diamondPath, fillPaint);

    // Stroke
    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(diamondPath, strokePaint);

    // Internal facet lines
    final facetPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Top-left to center
    canvas.drawLine(Offset(cx, unit * 0.08), Offset(unit * 0.32, cy), facetPaint);
    // Top-right to center
    canvas.drawLine(Offset(cx, unit * 0.08), Offset(unit * 0.68, cy), facetPaint);
    // Horizontal mid-line
    canvas.drawLine(Offset(unit * 0.12, cy), Offset(unit * 0.88, cy), facetPaint);

    // Sparkle dots (soft glow)
    final sparklePaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.drawCircle(Offset(unit * 0.18, unit * 0.22), 1.8, sparklePaint);
    canvas.drawCircle(Offset(unit * 0.82, unit * 0.30), 1.4, sparklePaint);
    canvas.drawCircle(Offset(unit * 0.75, unit * 0.78), 1.6, sparklePaint);
  }

  @override
  bool shouldRepaint(_OracleIconPainter old) => old.color != color;
}

/// Groups: Three overlapping person silhouettes.
class _GroupsIconPainter extends CustomPainter {
  final Color color;
  const _GroupsIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width;
    final cy = size.height * 0.5;

    // Draw a person silhouette: circle head + shoulder arc
    void drawPerson(double headX, double headY, double headR, double shoulderW,
        double shoulderH, double alpha) {
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      // Head
      canvas.drawCircle(Offset(headX, headY), headR, paint);

      // Shoulder arc (half-ellipse below head)
      final shoulderRect = Rect.fromCenter(
        center: Offset(headX, headY + headR + shoulderH * 0.45),
        width: shoulderW,
        height: shoulderH,
      );
      canvas.drawArc(shoulderRect, math.pi, math.pi, false,
          paint..style = PaintingStyle.fill);

      // Fill the shoulder body
      final bodyPath = Path()
        ..addArc(shoulderRect, math.pi, math.pi);
      canvas.drawPath(bodyPath, paint);
    }

    // Back-left person (smaller, semi-transparent)
    drawPerson(
      unit * 0.22, cy - unit * 0.06,
      unit * 0.10, unit * 0.30, unit * 0.26,
      0.50,
    );

    // Back-right person (smaller, semi-transparent)
    drawPerson(
      unit * 0.78, cy - unit * 0.06,
      unit * 0.10, unit * 0.30, unit * 0.26,
      0.50,
    );

    // Front-center person (larger, fully opaque)
    drawPerson(
      unit * 0.50, cy - unit * 0.10,
      unit * 0.13, unit * 0.38, unit * 0.32,
      0.95,
    );
  }

  @override
  bool shouldRepaint(_GroupsIconPainter old) => old.color != color;
}

/// Exam: Clipboard with text lines and a checkmark.
class _ExamIconPainter extends CustomPainter {
  final Color color;
  const _ExamIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width;

    // Clipboard body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(unit * 0.15, unit * 0.15, unit * 0.70, unit * 0.78),
      const Radius.circular(3.0),
    );
    final bodyPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bodyRect, bodyPaint);

    final bodyStroke = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(bodyRect, bodyStroke);

    // Clipboard clip (tab at top center)
    final clipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(unit * 0.50, unit * 0.15),
        width: unit * 0.30,
        height: unit * 0.12,
      ),
      const Radius.circular(2.0),
    );
    final clipPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(clipRect, clipPaint);

    // Text lines
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(unit * 0.28, unit * 0.38),
      Offset(unit * 0.72, unit * 0.38),
      linePaint,
    );
    canvas.drawLine(
      Offset(unit * 0.28, unit * 0.50),
      Offset(unit * 0.65, unit * 0.50),
      linePaint,
    );
    canvas.drawLine(
      Offset(unit * 0.28, unit * 0.62),
      Offset(unit * 0.55, unit * 0.62),
      linePaint,
    );

    // Checkmark (bottom-right area)
    final checkPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(unit * 0.48, unit * 0.76)
      ..lineTo(unit * 0.57, unit * 0.85)
      ..lineTo(unit * 0.72, unit * 0.70);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(_ExamIconPainter old) => old.color != color;
}

// ---------------------------------------------------------------------------
// Notification Badge
// ---------------------------------------------------------------------------

/// Small red notification badge with a count number.
class _NotificationBadge extends StatelessWidget {
  final int count;

  const _NotificationBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    final minWidth =
        label.length > 2 ? 24.0 : (label.length > 1 ? 22.0 : 18.0);

    return Container(
      constraints: BoxConstraints(minWidth: minWidth, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/math_text.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../data/models/snap_solution_model.dart';

/// Displays a step-by-step AI solution with expandable steps,
/// solution feedback buttons, and a step-by-step toggle.
class SolutionView extends StatefulWidget {
  final SnapSolutionModel solution;
  final VoidCallback? onSolveAnother;

  const SolutionView({
    super.key,
    required this.solution,
    this.onSolveAnother,
  });

  @override
  State<SolutionView> createState() => _SolutionViewState();
}

class _SolutionViewState extends State<SolutionView> {
  /// Whether to show steps as individual collapsible cards.
  bool _showSteps = true;

  /// Track which steps are expanded (by index). All expanded by default.
  late List<bool> _expandedSteps;

  /// The user's feedback rating for this solution, if any.
  _FeedbackType? _selectedFeedback;

  /// Whether the thank-you message is currently visible.
  bool _showThankYou = false;

  @override
  void initState() {
    super.initState();
    final stepCount = _effectiveSteps.length;
    _expandedSteps = List.filled(stepCount, true);
    _loadFeedback();
  }

  @override
  void didUpdateWidget(covariant SolutionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.solution.id != widget.solution.id) {
      final stepCount = _effectiveSteps.length;
      _expandedSteps = List.filled(stepCount, true);
      _selectedFeedback = null;
      _showThankYou = false;
      _loadFeedback();
    }
  }

  /// Returns a unique key for this solution for SharedPreferences storage.
  String get _feedbackKey {
    final id = widget.solution.id;
    if (id != null && id.isNotEmpty) return 'snap_feedback_$id';
    // Fallback: hash from problem text + creation time
    final hash = widget.solution.solution.problem.hashCode ^
        (widget.solution.createdAt?.millisecondsSinceEpoch ?? 0);
    return 'snap_feedback_$hash';
  }

  /// Try to parse the solution into steps. If structured steps exist, use them.
  /// Otherwise, try to split the explanation/finalAnswer by numbered lines.
  List<SolutionStep> get _effectiveSteps {
    final data = widget.solution.solution;
    if (data.steps.isNotEmpty) return data.steps;

    // Try to extract steps from the explanation or finalAnswer text.
    final text = data.explanation.isNotEmpty ? data.explanation : data.finalAnswer;
    return _parseStepsFromText(text);
  }

  /// Whether the solution has clear discrete steps (structured or parseable).
  bool get _hasMultipleSteps => _effectiveSteps.length > 1;

  /// Attempt to split a text block into numbered steps.
  List<SolutionStep> _parseStepsFromText(String text) {
    if (text.isEmpty) return [];

    // Try splitting on numbered step patterns: "1.", "1)", "Step 1:", etc.
    final stepPattern = RegExp(
      r'(?:^|\n)\s*(?:(?:step\s+)?(\d+)[.):\-]\s*)',
      caseSensitive: false,
    );

    final matches = stepPattern.allMatches(text).toList();

    if (matches.length >= 2) {
      final steps = <SolutionStep>[];
      for (var i = 0; i < matches.length; i++) {
        final start = matches[i].end;
        final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
        final content = text.substring(start, end).trim();
        if (content.isNotEmpty) {
          steps.add(SolutionStep(
            step: i + 1,
            title: 'Step ${i + 1}',
            content: content,
          ));
        }
      }
      if (steps.isNotEmpty) return steps;
    }

    // Try splitting by double newlines
    final paragraphs =
        text.split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).toList();
    if (paragraphs.length >= 2) {
      return paragraphs.asMap().entries.map((e) {
        return SolutionStep(
          step: e.key + 1,
          title: 'Step ${e.key + 1}',
          content: e.value.trim(),
        );
      }).toList();
    }

    // Single block: not splittable
    return [];
  }

  Future<void> _loadFeedback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_feedbackKey);
      if (value != null && mounted) {
        setState(() {
          _selectedFeedback = _FeedbackType.values.firstWhere(
            (f) => f.name == value,
            orElse: () => _FeedbackType.helpful,
          );
        });
      }
    } catch (e) {
      // Ignore errors reading preferences
      debugPrint('SolutionView: loadFeedback failed: $e');
    }
  }

  Future<void> _saveFeedback(_FeedbackType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_feedbackKey, type.name);
    } catch (e) {
      // Ignore errors writing preferences
      debugPrint('SolutionView: saveFeedback failed: $e');
    }
  }

  void _onFeedbackTap(_FeedbackType type) {
    if (_selectedFeedback != null) return; // Already rated

    HapticFeedback.mediumImpact();
    setState(() {
      _selectedFeedback = type;
      _showThankYou = true;
    });
    _saveFeedback(type);

    // Auto-hide thank-you message after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showThankYou = false);
      }
    });
  }

  void _toggleStep(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _expandedSteps[index] = !_expandedSteps[index];
    });
  }

  void _toggleShowSteps() {
    HapticFeedback.lightImpact();
    setState(() {
      _showSteps = !_showSteps;
      if (_showSteps) {
        // Re-expand all when turning steps back on
        _expandedSteps = List.filled(_effectiveSteps.length, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.solution.solution;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),

          // Subject tag
          _SubjectTag(subject: data.subject),

          const SizedBox(height: AppSpacing.lg),

          // Problem text
          if (data.problem.isNotEmpty) ...[
            Text(
              'Problem',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white38,
                letterSpacing: 1.2,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: MathText(
                text: data.problem,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Solution header with step toggle
          _buildSolutionHeader(),

          const SizedBox(height: AppSpacing.md),

          // Steps or full solution block
          if (_showSteps && _hasMultipleSteps)
            ..._effectiveSteps.asMap().entries.map(
                  (entry) => _CollapsibleStepCard(
                    step: entry.value,
                    isExpanded: entry.key < _expandedSteps.length
                        ? _expandedSteps[entry.key]
                        : true,
                    onToggle: () => _toggleStep(entry.key),
                  ),
                )
          else if (_effectiveSteps.isNotEmpty)
            ..._effectiveSteps.map((step) => _StepCard(step: step))
          else if (data.explanation.isNotEmpty)
            _FullSolutionBlock(text: data.explanation)
          else
            _FullSolutionBlock(text: data.finalAnswer),

          const SizedBox(height: AppSpacing.xl),

          // Final answer
          _FinalAnswerCard(answer: data.finalAnswer),

          // Explanation
          if (data.explanation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: const Color(0xFFFBBF24),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: MathText(
                      text: data.explanation,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white60,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // ── Alternative Methods ──
          const _AlternativeMethodsSection(),

          const SizedBox(height: AppSpacing.lg),

          // ── Feedback Buttons ──
          _buildFeedbackSection(),

          const SizedBox(height: AppSpacing.xl),

          // Solve another button
          if (widget.onSolveAnother != null)
            TapScale(
              onTap: widget.onSolveAnother,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Solve Another',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  // ── Solution Header with Toggle ──

  Widget _buildSolutionHeader() {
    return Row(
      children: [
        Text(
          'SOLUTION',
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white38,
            letterSpacing: 1.5,
            fontSize: 10,
          ),
        ),
        const Spacer(),
        if (_hasMultipleSteps)
          TapScale(
            onTap: _toggleShowSteps,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: _showSteps
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _showSteps
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showSteps
                        ? Icons.view_agenda_rounded
                        : Icons.subject_rounded,
                    size: 14,
                    color: _showSteps ? AppColors.primary : Colors.white38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showSteps ? 'Show steps' : 'Full solution',
                    style: AppTypography.caption.copyWith(
                      color: _showSteps ? AppColors.primary : Colors.white38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── Feedback Section ──

  Widget _buildFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Was this solution helpful?',
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white38,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _FeedbackPill(
              emoji: '\uD83D\uDC4D',
              label: 'Helpful',
              type: _FeedbackType.helpful,
              selectedType: _selectedFeedback,
              onTap: () => _onFeedbackTap(_FeedbackType.helpful),
            ),
            const SizedBox(width: AppSpacing.xs),
            _FeedbackPill(
              emoji: '\uD83D\uDE15',
              label: 'Unclear',
              type: _FeedbackType.unclear,
              selectedType: _selectedFeedback,
              onTap: () => _onFeedbackTap(_FeedbackType.unclear),
            ),
            const SizedBox(width: AppSpacing.xs),
            _FeedbackPill(
              emoji: '\uD83D\uDC4E',
              label: 'Wrong',
              type: _FeedbackType.wrong,
              selectedType: _selectedFeedback,
              onTap: () => _onFeedbackTap(_FeedbackType.wrong),
            ),
          ],
        ),
        // Thank-you message
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: _showThankYou
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    'Thanks for your feedback!',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// Feedback Types & Pill Button
// ═══════════════════════════════════════════

enum _FeedbackType { helpful, unclear, wrong }

class _FeedbackPill extends StatelessWidget {
  final String emoji;
  final String label;
  final _FeedbackType type;
  final _FeedbackType? selectedType;
  final VoidCallback onTap;

  const _FeedbackPill({
    required this.emoji,
    required this.label,
    required this.type,
    required this.selectedType,
    required this.onTap,
  });

  bool get _isSelected => selectedType == type;
  bool get _hasSelection => selectedType != null;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (_isSelected) {
      // Selected state
      bgColor = AppColors.primary.withValues(alpha: 0.15);
      borderColor = AppColors.primary.withValues(alpha: 0.4);
      textColor = AppColors.primary;
    } else if (_hasSelection) {
      // Another option is selected - fade this one
      bgColor = Colors.white.withValues(alpha: 0.03);
      borderColor = Colors.white.withValues(alpha: 0.06);
      textColor = Colors.white.withValues(alpha: 0.25);
    } else {
      // No selection yet - normal state
      bgColor = Colors.white.withValues(alpha: 0.06);
      borderColor = Colors.white.withValues(alpha: 0.1);
      textColor = Colors.white60;
    }

    return TapScale(
      onTap: _hasSelection ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs + 2,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: textColor,
                fontWeight: _isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (_isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_rounded,
                size: 12,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Subject Tag
// ═══════════════════════════════════════════

class _SubjectTag extends StatelessWidget {
  final String subject;

  const _SubjectTag({required this.subject});

  Color get _color {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return const Color(0xFF3B82F6);
      case 'physics':
        return const Color(0xFF8B5CF6);
      case 'chemistry':
        return const Color(0xFF22C55E);
      case 'biology':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFFF97316);
    }
  }

  IconData get _icon {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return Icons.functions;
      case 'physics':
        return Icons.science;
      case 'chemistry':
        return Icons.biotech;
      case 'biology':
        return Icons.eco;
      default:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 6),
          Text(
            subject,
            style: AppTypography.labelMedium.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Collapsible Step Card (for step-by-step toggle)
// ═══════════════════════════════════════════

class _CollapsibleStepCard extends StatelessWidget {
  final SolutionStep step;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _CollapsibleStepCard({
    required this.step,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GestureDetector(
        onTap: onToggle,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isExpanded
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isExpanded
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row (always visible)
              Row(
                children: [
                  // Step number badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${step.step}',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      step.title,
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),

              // Expandable content
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    left: 40, // align with text after step number
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MathText(
                        text: step.content,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white60,
                          height: 1.6,
                        ),
                      ),
                      // Formula (if present)
                      if (step.formula != null &&
                          step.formula!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: MathText(
                            text: step.formula!.contains('\$')
                                ? step.formula!
                                : '\$${step.formula!}\$',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
                sizeCurve: Curves.easeOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Step Card (non-collapsible, original style)
// ═══════════════════════════════════════════

class _StepCard extends StatelessWidget {
  final SolutionStep step;

  const _StepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Text(
                '${step.step}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Step content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                MathText(
                  text: step.content,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white60,
                    height: 1.6,
                  ),
                ),

                // Formula (if present)
                if (step.formula != null && step.formula!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: MathText(
                      text: step.formula!.contains('\$')
                          ? step.formula!
                          : '\$${step.formula!}\$',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Full Solution Block (when steps toggle is off)
// ═══════════════════════════════════════════

class _FullSolutionBlock extends StatelessWidget {
  final String text;

  const _FullSolutionBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: MathText(
        text: text,
        style: AppTypography.bodySmall.copyWith(
          color: Colors.white60,
          height: 1.6,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Final Answer Card
// ═══════════════════════════════════════════

class _FinalAnswerCard extends StatelessWidget {
  final String answer;

  const _FinalAnswerCard({required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primaryLight.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Final Answer',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          MathText(
            text: answer,
            style: AppTypography.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Alternative Methods Expandable Section
// ═══════════════════════════════════════════

class _AlternativeMethodsSection extends StatefulWidget {
  const _AlternativeMethodsSection();

  @override
  State<_AlternativeMethodsSection> createState() =>
      _AlternativeMethodsSectionState();
}

class _AlternativeMethodsSectionState
    extends State<_AlternativeMethodsSection> {
  bool _isExpanded = false;

  static const _approaches = [
    _ApproachChip(
      label: 'Step-by-step',
      icon: Icons.format_list_numbered_rounded,
    ),
    _ApproachChip(
      label: 'Visual/Graphical',
      icon: Icons.auto_graph_rounded,
    ),
    _ApproachChip(
      label: 'Conceptual',
      icon: Icons.lightbulb_outline_rounded,
    ),
  ];

  void _toggleExpand() {
    HapticFeedback.selectionClick();
    setState(() => _isExpanded = !_isExpanded);
  }

  void _onChipTap(String label) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text('Generating alternative ($label)...'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Tappable header row ──
          GestureDetector(
            onTap: _toggleExpand,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.straighten_rounded,
                      size: 15,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Alternative Method',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable content ──
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(
                          color: Colors.white.withValues(alpha: 0.06),
                          height: 1,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Try solving this a different way...',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white38,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: _approaches
                              .map(
                                (chip) => TapScale(
                                  onTap: () => _onChipTap(chip.label),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xxs + 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B5CF6)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF8B5CF6)
                                            .withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          chip.icon,
                                          size: 14,
                                          color: const Color(0xFF8B5CF6),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          chip.label,
                                          style:
                                              AppTypography.caption.copyWith(
                                            color: const Color(0xFF8B5CF6),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Data class for approach chip configuration.
class _ApproachChip {
  final String label;
  final IconData icon;

  const _ApproachChip({required this.label, required this.icon});
}

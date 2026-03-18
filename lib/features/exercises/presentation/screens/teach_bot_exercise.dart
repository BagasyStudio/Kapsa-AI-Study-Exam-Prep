import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';
import 'exercise_screen.dart';

/// Teach the Bot exercise.
///
/// Data format: JSON object with `topic`, `botQuestion`,
/// `keyPoints` (array of strings), `followUpQuestions` (array of strings).
/// Chat-like interface where student explains a topic to a bot.
class TeachBotExercise extends StatefulWidget {
  final dynamic data;
  final String courseId;
  final void Function(int score) onComplete;

  const TeachBotExercise({
    super.key,
    required this.data,
    required this.courseId,
    required this.onComplete,
  });

  @override
  State<TeachBotExercise> createState() => _TeachBotExerciseState();
}

class _TeachBotExerciseState extends State<TeachBotExercise>
    with TickerProviderStateMixin {
  static const _accentColor = Color(0xFF8B5CF6);

  String _topic = '';
  String _botQuestion = '';
  List<String> _keyPoints = [];
  List<String> _followUpQuestions = [];

  final _messages = <_ChatMessage>[];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _hasSubmitted = false;
  bool _showAnalysis = false;
  List<bool> _coveredPoints = [];
  bool _isComplete = false;
  int _score = 0;

  late AnimationController _analysisAnimController;
  late Animation<double> _analysisAnim;

  @override
  void initState() {
    super.initState();
    _analysisAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _analysisAnim = CurvedAnimation(
      parent: _analysisAnimController,
      curve: Curves.easeOutCubic,
    );
    _parseData();
    // Add initial bot message
    if (_botQuestion.isNotEmpty) {
      _messages.add(_ChatMessage(
        text: _botQuestion,
        isBot: true,
      ));
    }
  }

  void _parseData() {
    try {
      final map = widget.data as Map;
      _topic = map['topic'] as String? ?? '';
      _botQuestion = map['botQuestion'] as String? ?? '';
      final kp = map['keyPoints'] as List?;
      _keyPoints = kp?.map((e) => e.toString()).toList() ?? [];
      final fq = map['followUpQuestions'] as List?;
      _followUpQuestions = fq?.map((e) => e.toString()).toList() ?? [];
      _coveredPoints = List.filled(_keyPoints.length, false);
    } catch (_) {
      _topic = '';
      _botQuestion = '';
      _keyPoints = [];
      _followUpQuestions = [];
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _analysisAnimController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(_ChatMessage(text: text, isBot: false));
      _controller.clear();
    });

    _scrollToBottom();

    // Analyze key points coverage
    _analyzeResponse(text);
  }

  void _analyzeResponse(String response) {
    final lowerResponse = response.toLowerCase();
    for (int i = 0; i < _keyPoints.length; i++) {
      if (_coveredPoints[i]) continue;
      // Check if key point is mentioned (case-insensitive contains)
      final keyPointLower = _keyPoints[i].toLowerCase();
      if (lowerResponse.contains(keyPointLower)) {
        _coveredPoints[i] = true;
        continue;
      }
      // Also check individual significant words
      final keywords = keyPointLower
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 3)
          .toList();
      final matchCount =
          keywords.where((k) => lowerResponse.contains(k)).length;
      if (keywords.isNotEmpty &&
          matchCount >= (keywords.length * 0.5).ceil()) {
        _coveredPoints[i] = true;
      }
    }

    // Calculate score
    final covered = _coveredPoints.where((c) => c).length;
    _score = _keyPoints.isEmpty
        ? 100
        : ((covered / _keyPoints.length) * 100).round();

    setState(() {
      _hasSubmitted = true;
      _showAnalysis = true;
    });
    _analysisAnimController.forward(from: 0);
  }

  void _useSuggestion(String suggestion) {
    setState(() {
      _showAnalysis = false;
      _messages.add(_ChatMessage(text: suggestion, isBot: true));
    });
    _scrollToBottom();
    _analysisAnimController.reset();
  }

  void _finish() {
    setState(() => _isComplete = true);
    widget.onComplete(_score);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_botQuestion.isEmpty) {
      return Column(
        children: [
          const ExerciseHeader(
            title: 'Teach the Bot',
            accentColor: _accentColor,
            icon: Icons.school_rounded,
          ),
          const Expanded(
            child: Center(
              child: Text('No data available',
                  style: TextStyle(color: Colors.white60)),
            ),
          ),
        ],
      );
    }

    if (_isComplete) {
      return Column(
        children: [
          const ExerciseHeader(
            title: 'Teach the Bot',
            accentColor: _accentColor,
            icon: Icons.school_rounded,
          ),
          Expanded(
            child: ExerciseCompleteCard(
              score: _coveredPoints.where((c) => c).length,
              total: _keyPoints.length,
              accentColor: _accentColor,
              courseId: widget.courseId,
              onFinish: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        ExerciseHeader(
          title: 'Teach the Bot',
          subtitle: _topic,
          accentColor: _accentColor,
          icon: Icons.school_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── Chat messages ──
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            itemCount: _messages.length + (_showAnalysis ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < _messages.length) {
                return _buildChatBubble(_messages[index]);
              }
              // Analysis card
              return _buildAnalysisCard();
            },
          ),
        ),

        // ── Follow-up suggestions ──
        if (_showAnalysis && _followUpQuestions.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.xs),
              itemCount: _followUpQuestions.length,
              itemBuilder: (context, index) {
                return TapScale(
                  onTap: () =>
                      _useSuggestion(_followUpQuestions[index]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: _accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _followUpQuestions[index],
                      style: AppTypography.caption.copyWith(
                        color: _accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: AppSpacing.xs),

        // ── Input bar ──
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.immersiveSurface,
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: AppTypography.bodyMedium
                        .copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Explain the concept...',
                      hintStyle: AppTypography.bodySmall
                          .copyWith(color: Colors.white30),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              TapScale(
                onTap: _sendMessage,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accentColor,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_hasSubmitted) ...[
                const SizedBox(width: AppSpacing.xs),
                TapScale(
                  onTap: _finish,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.ctaLime,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: AppColors.ctaLimeText,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(_ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment:
            message.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isBot) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentColor.withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 16,
                color: _accentColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: message.isBot
                    ? AppColors.immersiveCard
                    : _accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft:
                      Radius.circular(message.isBot ? 4 : 14),
                  bottomRight:
                      Radius.circular(message.isBot ? 14 : 4),
                ),
                border: Border.all(
                  color: message.isBot
                      ? AppColors.immersiveBorder
                      : _accentColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                message.text,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (!message.isBot) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard() {
    return FadeTransition(
      opacity: _analysisAnim,
      child: Container(
        margin: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.md,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.immersiveCard,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: _accentColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_rounded,
                    size: 16, color: _accentColor),
                const SizedBox(width: 6),
                Text(
                  'Key Points Coverage',
                  style: AppTypography.labelMedium.copyWith(
                    color: _accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$_score%',
                    style: AppTypography.caption.copyWith(
                      color: _accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...List.generate(_keyPoints.length, (i) {
              final covered = _coveredPoints[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      covered
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color:
                          covered ? AppColors.success : Colors.white30,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _keyPoints[i],
                        style: AppTypography.bodySmall.copyWith(
                          color: covered
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.white38,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isBot;

  const _ChatMessage({required this.text, required this.isBot});
}

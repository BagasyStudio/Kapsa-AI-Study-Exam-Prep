import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../../core/constants/app_limits.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tap_scale.dart';

/// Chat input bar with multiline text field, send/stop action button, and voice input.
///
/// Fixed at the bottom of the chat screen. Solid background (no glass blur).
/// Shows a send button by default, switches to a stop button when [isLoading].
///
/// Enhancements:
/// - Character count indicator when message is > 100 chars
/// - Long-press on send button area to clear the input
/// - Auto-focus on the input when [autoFocus] is true
/// - Pulsing dot animation in the input hint when AI is loading
/// - Microphone button for voice-to-text input via speech_to_text
class ChatInputBar extends StatefulWidget {
  final TextEditingController? controller;
  final VoidCallback? onSend;
  final VoidCallback? onStop;
  final ValueChanged<String>? onChanged;
  final bool isLoading;
  final bool autoFocus;

  const ChatInputBar({
    super.key,
    this.controller,
    this.onSend,
    this.onStop,
    this.onChanged,
    this.isLoading = false,
    this.autoFocus = true,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  int _charCount = 0;

  // Voice input state
  final SpeechToText _speechToText = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _charCount = widget.controller?.text.length ?? 0;
    widget.controller?.addListener(_onTextChanged);

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }

    // Initialize pulse animation for recording indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize speech recognition
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speechToText.initialize(
        onError: (error) {
          if (mounted) {
            setState(() => _isListening = false);
            _pulseController.stop();
          }
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted && _isListening) {
              setState(() => _isListening = false);
              _pulseController.stop();
            }
          }
        },
      );
    } catch (_) {
      _speechAvailable = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Voice input not available on this device',
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.immersiveCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isListening = true);
    _pulseController.repeat(reverse: true);

    await _speechToText.listen(
      onResult: (result) {
        if (mounted && widget.controller != null) {
          final currentText = widget.controller!.text;
          final newText = currentText.isEmpty
              ? result.recognizedWords
              : '$currentText ${result.recognizedWords}';
          widget.controller!.text = newText;
          widget.controller!.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller!.text.length),
          );
          widget.onChanged?.call(widget.controller!.text);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> _stopListening() async {
    HapticFeedback.lightImpact();
    await _speechToText.stop();
    if (mounted) {
      setState(() => _isListening = false);
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onTextChanged);
    _focusNode.dispose();
    _pulseController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  void _onTextChanged() {
    final newCount = widget.controller?.text.length ?? 0;
    if (newCount != _charCount) {
      setState(() => _charCount = newCount);
    }
  }

  void _onLongPressClear() {
    if (widget.controller != null && widget.controller!.text.isNotEmpty) {
      HapticFeedback.mediumImpact();
      widget.controller!.clear();
      setState(() => _charCount = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final backgroundColor = AppColors.cardDark;

    final topBorderColor = Colors.white.withValues(alpha: 0.08);

    final fieldBackground = Colors.white.withValues(alpha: 0.06);

    final hintColor = Colors.white38;
    final textColor = Colors.white;

    // Determine action button properties based on loading state.
    final actionColor = widget.isLoading ? AppColors.error : AppColors.primary;

    final showCharCount = _charCount > 100;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        bottomPadding + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(color: topBorderColor),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording indicator
          if (_isListening)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.error
                              .withValues(alpha: _pulseAnimation.value),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Listening...',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error
                              .withValues(alpha: _pulseAnimation.value),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Text field
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  decoration: BoxDecoration(
                    color: _isListening
                        ? AppColors.error.withValues(alpha: 0.06)
                        : fieldBackground,
                    borderRadius: BorderRadius.circular(22),
                    border: _isListening
                        ? Border.all(
                            color: AppColors.error.withValues(alpha: 0.2))
                        : null,
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    onChanged: (value) {
                      widget.onChanged?.call(value);
                    },
                    maxLength: AppLimits.maxChatMessageLength,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                        AppLimits.maxChatMessageLength,
                      ),
                    ],
                    style:
                        AppTypography.bodyMedium.copyWith(color: textColor),
                    textInputAction: TextInputAction.newline,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          _isListening ? 'Speak now...' : 'Ask anything...',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: _isListening
                            ? AppColors.error.withValues(alpha: 0.5)
                            : hintColor,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Microphone button
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: TapScale(
                  onTap: _isListening ? _stopListening : _startListening,
                  scaleDown: 0.90,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? AppColors.error.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.08),
                      border: _isListening
                          ? Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: _isListening ? AppColors.error : Colors.white54,
                      size: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Action button (send / stop) with long-press to clear
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: GestureDetector(
                  onLongPress: _onLongPressClear,
                  child: TapScale(
                    onTap: widget.isLoading ? widget.onStop : widget.onSend,
                    scaleDown: 0.90,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: actionColor,
                        boxShadow: [
                          BoxShadow(
                            color: actionColor.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: widget.isLoading
                            ? const Icon(
                                Icons.stop_rounded,
                                key: ValueKey('stop'),
                                color: Colors.white,
                                size: 22,
                              )
                            : const Icon(
                                Icons.arrow_upward,
                                key: ValueKey('send'),
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Character count indicator (visible when > 100 chars)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: showCharCount
                ? Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.xxs,
                      right: AppSpacing.xs,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$_charCount/${AppLimits.maxChatMessageLength}',
                        style: AppTypography.caption.copyWith(
                          color: _charCount >
                                  (AppLimits.maxChatMessageLength * 0.9).toInt()
                              ? AppColors.warning
                              : Colors.white30,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

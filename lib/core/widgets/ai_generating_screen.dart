import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Beautiful full-screen animation shown while AI generates content.
///
/// Displays a pulsing neural-orb with floating particles and
/// animated status text. Used for flashcard/quiz generation.
class AiGeneratingScreen extends StatefulWidget {
  /// Type of content being generated (e.g. 'flashcards', 'quiz').
  final String type;

  /// Optional course title to display context.
  final String? courseTitle;

  /// Callback when generation completes or the user cancels.
  final VoidCallback? onCancel;

  const AiGeneratingScreen({
    super.key,
    required this.type,
    this.courseTitle,
    this.onCancel,
  });

  @override
  State<AiGeneratingScreen> createState() => _AiGeneratingScreenState();
}

class _AiGeneratingScreenState extends State<AiGeneratingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _textController;
  int _statusIndex = 0;

  List<String> get _statusMessages {
    if (widget.type == 'flashcards') {
      return [
        'Reading your materials...',
        'Identifying key concepts...',
        'Crafting questions...',
        'Creating flashcards...',
        'Almost ready...',
      ];
    } else {
      return [
        'Analyzing your materials...',
        'Generating questions...',
        'Creating answer keys...',
        'Building your quiz...',
        'Almost ready...',
      ];
    }
  }

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _statusIndex =
                (_statusIndex + 1) % _statusMessages.length;
          });
          _textController.reset();
          _textController.forward();
        }
      });
    _textController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.darkImmersive),
        child: Stack(
          children: [
            // Floating particles
            ..._buildParticles(),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Top bar with cancel
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (widget.onCancel != null)
                          GestureDetector(
                            onTap: widget.onCancel,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                'Cancel',
                                style: AppTypography.labelLarge.copyWith(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Centered orb
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Neural orb
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: AnimatedBuilder(
                              animation: Listenable.merge(
                                  [_pulseController, _rotateController]),
                              builder: (context, child) {
                                final pulse = _pulseController.value;
                                final scale = 0.85 + (pulse * 0.15);
                                final rotation = _rotateController.value * 2 * pi;

                                return Transform.scale(
                                  scale: scale,
                                  child: Transform.rotate(
                                    angle: rotation,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            const Color(0xFF8B5CF6)
                                                .withValues(alpha: 0.6),
                                            const Color(0xFF6467F2)
                                                .withValues(alpha: 0.3),
                                            Colors.transparent,
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF6467F2)
                                                .withValues(alpha: 0.3 + pulse * 0.2),
                                            blurRadius: 40 + pulse * 20,
                                            spreadRadius: 10,
                                          ),
                                          BoxShadow(
                                            color: const Color(0xFF8B5CF6)
                                                .withValues(alpha: 0.2),
                                            blurRadius: 60,
                                            spreadRadius: 20,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Transform.rotate(
                                          angle: -rotation,
                                          child: Icon(
                                            widget.type == 'flashcards'
                                                ? Icons.style
                                                : Icons.quiz,
                                            size: 48,
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Title
                          Text(
                            widget.type == 'flashcards'
                                ? 'Creating Flashcards'
                                : 'Creating Quiz',
                            style: AppTypography.h2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          if (widget.courseTitle != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.courseTitle!,
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),

                          // Animated status text
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: Text(
                              _statusMessages[_statusIndex],
                              key: ValueKey(_statusIndex),
                              style: AppTypography.bodyMedium.copyWith(
                                color: const Color(0xFFA5A7FA),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Progress dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _statusMessages.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _statusIndex ? 24 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == _statusIndex
                                      ? const Color(0xFF6467F2)
                                      : Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildParticles() {
    final rng = Random(42); // Fixed seed for consistent positions
    return List.generate(12, (i) {
      final top = rng.nextDouble() * MediaQuery.of(context).size.height;
      final left = rng.nextDouble() * MediaQuery.of(context).size.width;
      final size = 2.0 + rng.nextDouble() * 4;
      final delay = rng.nextDouble();

      return Positioned(
        top: top,
        left: left,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            final value = ((_pulseController.value + delay) % 1.0);
            return Opacity(
              opacity: (value * 0.6).clamp(0.05, 0.5),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFA5A7FA),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

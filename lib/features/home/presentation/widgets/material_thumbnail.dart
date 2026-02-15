import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Types of study material for visual differentiation.
enum StudyMaterialType { document, audio, flashcard, folder }

/// A single thumbnail card in the Recent Materials grid.
///
/// Each type gets a distinct, colorful preview area that matches
/// the mockup's visual richness (not just a gray placeholder icon).
class MaterialThumbnail extends StatelessWidget {
  final String title;
  final String subtitle;
  final StudyMaterialType type;
  final String? imageUrl;
  final VoidCallback? onTap;

  const MaterialThumbnail({
    super.key,
    required this.title,
    required this.subtitle,
    required this.type,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Special "New Folder" card
    if (type == StudyMaterialType.folder) {
      return _NewFolderCard(onTap: onTap);
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadius.borderRadiusXxl,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.45),
              borderRadius: AppRadius.borderRadiusXxl,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview area
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.xxl),
                      topRight: Radius.circular(AppRadius.xxl),
                    ),
                    child: Stack(
                      children: [
                        // Content preview - full width
                        Positioned.fill(child: _buildPreview()),
                        // Type icon badge (top right)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _typeIcon,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Info area
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.labelLarge.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData get _typeIcon => switch (type) {
        StudyMaterialType.document => Icons.description,
        StudyMaterialType.audio => Icons.mic,
        StudyMaterialType.flashcard => Icons.style,
        StudyMaterialType.folder => Icons.folder,
      };

  Widget _buildPreview() {
    return switch (type) {
      StudyMaterialType.document => const _DocumentPreview(),
      StudyMaterialType.audio => const _AudioPreview(),
      StudyMaterialType.flashcard => const _FlashcardPreview(),
      StudyMaterialType.folder => const SizedBox.shrink(),
    };
  }
}

/// Rich document preview — simulates a page with handwritten-style lines
/// and a warm gradient background (like the mockup's biology notes image).
class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF1F5F9), // slate-100
            Color(0xFFE2E8F0), // slate-200
            Color(0xFFE0E7FF), // indigo-100
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title line
            Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF94A3B8).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            // Subtitle line
            Container(
              width: 80,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF94A3B8).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 14),
            // Body lines
            _textLine(1.0, 0.2),
            const SizedBox(height: 5),
            _textLine(0.9, 0.15),
            const SizedBox(height: 5),
            _textLine(0.7, 0.18),
            const SizedBox(height: 5),
            _textLine(0.85, 0.12),
          ],
        ),
      ),
    );
  }

  Widget _textLine(double widthFactor, double opacity) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: Color(0xFF64748B).withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Audio waveform preview — indigo background with animated-looking bars.
class _AudioPreview extends StatelessWidget {
  const _AudioPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE0E7FF), // indigo-100
            Color(0xFFC7D2FE), // indigo-200
            Color(0xFFE0E7FF), // indigo-100
          ],
        ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(9, (i) {
            // Create varied heights for waveform effect
            const heights = [14, 28, 20, 38, 16, 34, 22, 30, 18];
            return Container(
              width: 3,
              height: heights[i].toDouble(),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(100),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Flashcard preview — purple/blue geometric gradient with abstract shapes.
class _FlashcardPreview extends StatelessWidget {
  const _FlashcardPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFDDD6FE), // violet-200
            Color(0xFFC4B5FD), // violet-300
            Color(0xFFBFDBFE), // blue-200
          ],
        ),
      ),
      child: CustomPaint(
        painter: _GeometricShapesPainter(),
      ),
    );
  }
}

/// Paints abstract geometric shapes (circles, rectangles) for flashcard preview.
class _GeometricShapesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Large circle (top-right area)
    paint.color = const Color(0xFF8B5CF6).withValues(alpha: 0.2);
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.3),
      size.width * 0.25,
      paint,
    );

    // Small circle (bottom-left)
    paint.color = const Color(0xFF6366F1).withValues(alpha: 0.15);
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.7),
      size.width * 0.15,
      paint,
    );

    // Rounded rectangle (center)
    paint.color = const Color(0xFF7C3AED).withValues(alpha: 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.45, size.height * 0.5),
          width: size.width * 0.35,
          height: size.height * 0.25,
        ),
        const Radius.circular(8),
      ),
      paint,
    );

    // Another small rounded rect (top-left)
    paint.color = const Color(0xFF818CF8).withValues(alpha: 0.18);
    canvas.save();
    canvas.translate(size.width * 0.25, size.height * 0.3);
    canvas.rotate(math.pi / 6);
    canvas.translate(-size.width * 0.25, -size.height * 0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.25, size.height * 0.3),
          width: size.width * 0.2,
          height: size.height * 0.15,
        ),
        const Radius.circular(6),
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// "New Folder" add card.
class _NewFolderCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _NewFolderCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadius.borderRadiusXxl,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.45),
              borderRadius: AppRadius.borderRadiusXxl,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'New Folder',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
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

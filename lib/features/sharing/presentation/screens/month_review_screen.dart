import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/xp_config.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../gamification/presentation/providers/xp_provider.dart';
import '../../data/models/month_review_model.dart';
import '../providers/month_review_provider.dart';
import '../widgets/shareable_card_base.dart';
import '../widgets/share_preview_sheet.dart';

class MonthReviewScreen extends ConsumerStatefulWidget {
  const MonthReviewScreen({super.key});

  @override
  ConsumerState<MonthReviewScreen> createState() => _MonthReviewScreenState();
}

class _MonthReviewScreenState extends ConsumerState<MonthReviewScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewAsync = ref.watch(monthReviewProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      body: reviewAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('No review data available yet',
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white70)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
        data: (review) => _buildStories(review),
      ),
    );
  }

  Widget _buildStories(MonthReviewModel review) {
    final slides = _buildSlides(review);
    final totalSlides = slides.length;

    return Stack(
      children: [
        // Page view
        PageView(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _currentPage = i),
          children: slides,
        ),

        // Top bar: progress indicators + close
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bars
                Row(
                  children: List.generate(totalSlides, (i) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: EdgeInsets.only(right: i < totalSlides - 1 ? 4 : 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: i <= _currentPage
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                // Close button
                Align(
                  alignment: Alignment.centerRight,
                  child: TapScale(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSlides(MonthReviewModel review) {
    return [
      // Slide 1: Welcome
      _SlideContainer(
        gradient: const [Color(0xFF0F0F23), Color(0xFF1A1040)],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('\u2728', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 20),
            Text(
              'Your ${review.monthName}',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
            ),
            Text(
              'in Kapsa',
              style: TextStyle(color: AppColors.primary, fontSize: 32, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              '${review.year}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16),
            ),
          ],
        ),
      ),

      // Slide 2: XP Earned
      _SlideContainer(
        gradient: const [Color(0xFF0A1628), Color(0xFF1A1040)],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 48),
            const SizedBox(height: 24),
            Text(
              '${review.totalXpEarned}',
              style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w800, height: 1),
            ),
            const SizedBox(height: 4),
            Text('XP Earned', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 18)),
            const SizedBox(height: 24),
            Text(
              '${review.activeDays} active days out of 30',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
            ),
          ],
        ),
      ),

      // Slide 3: Cards Reviewed
      _SlideContainer(
        gradient: const [Color(0xFF0A2818), Color(0xFF0F1F28)],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.style, color: Color(0xFF10B981), size: 48),
            const SizedBox(height: 24),
            Text(
              '${review.cardsReviewed}',
              style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w800, height: 1),
            ),
            const SizedBox(height: 4),
            Text('Flashcards Reviewed', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 18)),
            const SizedBox(height: 16),
            if (review.cardsReviewed > 100)
              Text(
                "That's like memorizing a whole textbook!",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),

      // Slide 4: Quiz Performance (conditional)
      if (review.quizzesTaken > 0)
        _SlideContainer(
          gradient: const [Color(0xFF1A1040), Color(0xFF28100A)],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.quiz, color: Color(0xFFF59E0B), size: 48),
              const SizedBox(height: 24),
              Text(
                '${review.averageQuizScore.round()}%',
                style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w800, height: 1),
              ),
              const SizedBox(height: 4),
              Text('Average Quiz Score', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 18)),
              const SizedBox(height: 16),
              Text(
                '${review.quizzesTaken} quizzes completed',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
              ),
            ],
          ),
        ),

      // Slide 5: Top Course
      _SlideContainer(
        gradient: const [Color(0xFF100A28), Color(0xFF1A1040)],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, color: AppColors.primary, size: 48),
            const SizedBox(height: 24),
            Text(
              'Top Course',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              review.topCourseName,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '${review.totalSessions} study sessions this month',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
            ),
          ],
        ),
      ),

      // Slide 6: Study Personality
      _SlideContainer(
        gradient: const [Color(0xFF1A0A28), Color(0xFF0F1A28)],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(review.personalityEmoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 20),
            Text(
              'You are...',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              StudyPersonality.personalities[review.studyPersonality]?.name ?? review.studyPersonality,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                review.personalityDescription,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),

      // Slide 7: Share
      _SlideContainer(
        gradient: const [Color(0xFF0F0F23), Color(0xFF1A1B3D)],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('\uD83C\uDF89', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 20),
            const Text(
              "That's a Wrap!",
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your ${review.monthName} highlights',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15),
            ),
            const SizedBox(height: 32),
            TapScale(
              onTap: () {
                HapticFeedback.mediumImpact();
                _shareMonthReview(review);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6467F2), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6467F2).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.ios_share, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Share My Review',
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
          ],
        ),
      ),
    ];
  }

  void _shareMonthReview(MonthReviewModel review) {
    final profile = ref.read(profileProvider).valueOrNull;
    final xpTotal = ref.read(xpTotalProvider).valueOrNull ?? 0;

    SharePreviewSheet.show(
      context,
      shareCard: _MonthReviewShareCard(
        review: review,
        userName: profile?.fullName ?? 'Student',
        xpLevel: XpConfig.levelFromXp(xpTotal),
      ),
      shareType: 'month_review',
    );
  }
}

class _SlideContainer extends StatelessWidget {
  final List<Color> gradient;
  final Widget child;

  const _SlideContainer({required this.gradient, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
          child: child,
        ),
      ),
    );
  }
}

/// Share card for month review (inline since it's only used here).
class _MonthReviewShareCard extends StatelessWidget {
  final MonthReviewModel review;
  final String userName;
  final int xpLevel;

  const _MonthReviewShareCard({
    required this.review,
    required this.userName,
    required this.xpLevel,
  });

  @override
  Widget build(BuildContext context) {
    final pInfo = StudyPersonality.personalities[review.studyPersonality];

    return ShareableCardBase(
      userName: userName,
      xpLevel: xpLevel,
      badgeText: pInfo?.name ?? review.studyPersonality,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${review.monthName} ${review.year}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            review.personalityEmoji,
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 8),
          Text(
            pInfo?.name ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),

          // Stats grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ShareStat(value: '${review.totalXpEarned}', label: 'XP Earned', icon: Icons.bolt, color: const Color(0xFFF59E0B)),
              _ShareStat(value: '${review.cardsReviewed}', label: 'Cards', icon: Icons.style, color: const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ShareStat(value: '${review.activeDays}', label: 'Active Days', icon: Icons.calendar_today, color: const Color(0xFF3B82F6)),
              _ShareStat(value: '${review.quizzesTaken}', label: 'Quizzes', icon: Icons.quiz, color: const Color(0xFF8B5CF6)),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            'Discover your study personality',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _ShareStat({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

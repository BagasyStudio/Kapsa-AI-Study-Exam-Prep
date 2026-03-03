import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/providers/revenue_cat_provider.dart';
import '../../../../core/services/revenue_cat_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/feature_row.dart';
import '../widgets/pricing_card.dart';
import '../../../../core/widgets/tap_scale.dart';

/// Paywall / Subscription screen.
///
/// Premium dark immersive background with animated gradient orbs,
/// feature list, pricing cards, and pulsing CTA.
/// Integrates with RevenueCat for real in-app purchases.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen>
    with TickerProviderStateMixin {
  bool _isYearlySelected = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _orbController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.25, end: 0.55).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  /// Whether the user is currently logged in.
  bool get _isLoggedIn =>
      Supabase.instance.client.auth.currentSession != null;

  /// Dismiss the paywall — navigate to login if unauthenticated, home if logged in.
  void _dismiss() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(_isLoggedIn ? Routes.home : Routes.login);
    }
  }

  /// Get the correct package from RevenueCat offerings.
  Package? _getSelectedPackage(Offerings? offerings) {
    final current = offerings?.current;
    if (current == null) return null;

    if (_isYearlySelected) {
      return current.annual ?? current.getPackage(RevenueCatService.yearlyProductId);
    } else {
      return current.monthly ?? current.getPackage(RevenueCatService.monthlyProductId);
    }
  }

  /// Handle the purchase CTA tap.
  Future<void> _onPurchaseTap() async {
    final offerings = await ref.read(offeringsProvider.future);
    final package = _getSelectedPackage(offerings);

    if (package == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Products not available. Please try again later.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final success = await ref.read(purchaseNotifierProvider.notifier).purchase(package);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to Kapsa Pro!'),
          duration: Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _dismiss();
      });
    }
  }

  /// Handle restore purchases tap.
  Future<void> _onRestoreTap() async {
    final success = await ref.read(purchaseNotifierProvider.notifier).restore();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Purchases restored! Welcome back to Pro.'
                : 'No previous purchases found.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      if (success) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _dismiss();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchaseState = ref.watch(purchaseNotifierProvider);
    final offeringsAsync = ref.watch(offeringsProvider);

    // Extract dynamic prices from offerings when available
    String yearlyPrice = '\$59.99';
    String yearlyMonthly = '\$5.00/mo';
    String monthlyPrice = '\$12.99';

    offeringsAsync.whenData((offerings) {
      final current = offerings?.current;
      if (current != null) {
        final annual = current.annual;
        final monthly = current.monthly;

        if (annual != null) {
          yearlyPrice = annual.storeProduct.priceString;
          final monthlyEquiv = annual.storeProduct.price / 12;
          yearlyMonthly = '\$${monthlyEquiv.toStringAsFixed(2)}/mo';
        }
        if (monthly != null) {
          monthlyPrice = monthly.storeProduct.priceString;
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D1E),
      body: Stack(
        children: [
          // Deep gradient base
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0B0D1E),
                    Color(0xFF111338),
                    Color(0xFF0F1029),
                    Color(0xFF0B0D1E),
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Animated ambient orbs
          AnimatedBuilder(
            animation: _orbController,
            builder: (context, _) {
              final t = _orbController.value;
              return Stack(
                children: [
                  // Top-left indigo orb
                  Positioned(
                    top: -80 + (t * 30),
                    left: -60 + (t * 20),
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF4338CA).withValues(alpha: 0.4),
                            const Color(0xFF4338CA).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Center-right purple orb
                  Positioned(
                    top: 200 - (t * 40),
                    right: -100 + (t * 30),
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF7C3AED).withValues(alpha: 0.3),
                            const Color(0xFF7C3AED).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom blue orb
                  Positioned(
                    bottom: -60 - (t * 20),
                    left: 40 + (t * 40),
                    child: Container(
                      width: 350,
                      height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF1E40AF).withValues(alpha: 0.25),
                            const Color(0xFF1E40AF).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Noise texture
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.04,
                child: CustomPaint(
                  painter: _NoisePainter(),
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // Close button
                  _GlassCloseButton(
                    onTap: _dismiss,
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Sparkle + label
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: const Color(0xFFFBBF24), // amber-400
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'KAPSA PRO',
                          style: AppTypography.caption.copyWith(
                            color: const Color(0xFFFBBF24),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Title
                  Text(
                    'Unlock Your\nFull Potential',
                    style: AppTypography.h1.copyWith(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Subtitle
                  Text(
                    'Join 50,000+ students achieving peak academic performance.',
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Social proof stats bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _SocialStat(value: '50K+', label: 'Students'),
                        Container(
                          width: 1,
                          height: 28,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        _SocialStat(value: '4.8', label: 'App Rating'),
                        Container(
                          width: 1,
                          height: 28,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        _SocialStat(value: '2x', label: 'Faster Learning'),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Features list
                  const FeatureRow(
                    icon: Icons.psychology_alt,
                    label: 'Unlimited AI Oracle Chat',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const FeatureRow(
                    icon: Icons.settings_suggest,
                    label: 'Instant Test Generation',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const FeatureRow(
                    icon: Icons.auto_graph,
                    label: 'Smart Study Plans',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const FeatureRow(
                    icon: Icons.insights,
                    label: 'Advanced Analytics & Insights',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const FeatureRow(
                    icon: Icons.headset,
                    label: 'Audio Summaries & Image Occlusion',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const FeatureRow(
                    icon: Icons.groups_rounded,
                    label: 'Unlimited Study Groups',
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Testimonial card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (_) => const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Color(0xFFFBBF24),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '"Kapsa Pro helped me raise my GPA from 3.2 to 3.8 in one semester. The AI quiz generation is a game changer."',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6467F2),
                                    Color(0xFF4338CA),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'S',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sarah M.',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Pre-Med Student',
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxxl),

                  // Pricing cards
                  Row(
                    children: [
                      Expanded(
                        child: PricingCard(
                          planName: 'Yearly',
                          price: yearlyPrice,
                          period: '/yr',
                          subtitle: yearlyMonthly,
                          badgeText: 'BEST VALUE — SAVE 62%',
                          isSelected: _isYearlySelected,
                          onTap: () =>
                              setState(() => _isYearlySelected = true),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: PricingCard(
                            planName: 'Monthly',
                            price: monthlyPrice,
                            period: '/mo',
                            isSelected: !_isYearlySelected,
                            onTap: () =>
                                setState(() => _isYearlySelected = false),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // CTA Button with pulsing glow
                  ListenableBuilder(
                    listenable: _pulseAnimation,
                    builder: (context, _) {
                      return Stack(
                        children: [
                          // Pulsing glow
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6467F2)
                                        .withValues(alpha: _pulseAnimation.value),
                                    blurRadius: 40,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Button
                          SizedBox(
                            width: double.infinity,
                            child: TapScale(
                              scaleDown: 0.96,
                              onTap: purchaseState.isLoading ? null : _onPurchaseTap,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF6467F2),
                                      Color(0xFF4338CA),
                                      Color(0xFF3730A3),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (purchaseState.isLoading)
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    else ...[
                                      Text(
                                        _isYearlySelected
                                            ? 'Start 7-Day Free Trial'
                                            : 'Get Kapsa Pro',
                                        style: AppTypography.button.copyWith(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white.withValues(alpha: 0.8),
                                        size: 20,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Restore purchases link
                  Center(
                    child: TapScale(
                      onTap: purchaseState.isLoading ? null : _onRestoreTap,
                      child: Text(
                        'Restore Purchases',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Money-back guarantee
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 16,
                            color: const Color(0xFF10B981).withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '7-Day Free Trial — Cancel Anytime',
                            style: AppTypography.caption.copyWith(
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Footer
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Cancel anytime. No questions asked.',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _TrustBadge(icon: Icons.shield_outlined, label: 'Secure'),
                            const SizedBox(width: AppSpacing.lg),
                            _TrustBadge(icon: Icons.lock_outline, label: 'Encrypted'),
                            const SizedBox(width: AppSpacing.lg),
                            _TrustBadge(icon: Icons.verified_outlined, label: 'Trusted'),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // ToS & Privacy Policy links (required by Apple)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => context.push(Routes.terms),
                              child: Text(
                                'Terms of Service',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  fontSize: 10,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '\u00b7',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push(Routes.privacy),
                              child: Text(
                                'Privacy Policy',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  fontSize: 10,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'USED BY STUDENTS AT STANFORD, MIT, AND OXFORD',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontWeight: FontWeight.w500,
                            fontSize: 9,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Trust badge for footer.
class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.white.withValues(alpha: 0.3),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Glass-styled close button.
class _GlassCloseButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _GlassCloseButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(
          Icons.close,
          color: Colors.white.withValues(alpha: 0.7),
          size: 20,
        ),
      ),
    );
  }
}

/// Social proof stat (value + label).
class _SocialStat extends StatelessWidget {
  final String value;
  final String label;

  const _SocialStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Subtle noise texture painter.
class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 3) {
      for (double y = 0; y < size.height; y += 3) {
        final hash = (x * 11 + y * 17).toInt() % 7;
        if (hash == 0) {
          canvas.drawCircle(Offset(x, y), 0.4, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

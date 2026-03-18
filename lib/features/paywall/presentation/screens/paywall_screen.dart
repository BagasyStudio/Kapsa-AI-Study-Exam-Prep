import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/providers/revenue_cat_provider.dart';
import '../../../../core/services/revenue_cat_service.dart';
import '../../../../core/widgets/tap_scale.dart';

/// Paywall / Subscription screen — Light theme for maximum contrast & trust.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isYearlySelected = true;

  bool get _isLoggedIn =>
      Supabase.instance.client.auth.currentSession != null;

  void _dismiss() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      ref.read(hasSeenOnboardingProvider.notifier).state = true;
      context.go(_isLoggedIn ? Routes.home : Routes.login);
    }
  }

  Package? _getSelectedPackage(Offerings? offerings) {
    final current = offerings?.current;
    if (current == null) return null;
    if (_isYearlySelected) {
      return current.annual ?? current.getPackage(RevenueCatService.yearlyProductId);
    } else {
      return current.weekly ?? current.getPackage(RevenueCatService.weeklyProductId);
    }
  }

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

    String yearlyPrice = '\$59.99';
    String yearlyMonthly = '\$5.00/mo';
    String weeklyPrice = '\$4.99';

    offeringsAsync.whenData((offerings) {
      final current = offerings?.current;
      if (current != null) {
        final annual = current.annual;
        final weekly = current.weekly ?? current.getPackage(RevenueCatService.weeklyProductId);
        if (annual != null) {
          yearlyPrice = annual.storeProduct.priceString;
          final monthlyEquiv = annual.storeProduct.price / 12;
          yearlyMonthly = '\$${monthlyEquiv.toStringAsFixed(2)}/mo';
        }
        if (weekly != null) {
          weeklyPrice = weekly.storeProduct.priceString;
        }
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // ── TOP BAR ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TapScale(
                      onTap: _dismiss,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F5F5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Color(0xFF374151), size: 20),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'KAPSA PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 2),

                // ── HEADLINE ──
                const Text(
                  'Unlock Your\nFull Potential',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Study smarter with unlimited AI power',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 32),

                // ── BENEFITS ──
                const _BenefitRow(
                  icon: Icons.chat_bubble_outline,
                  text: 'Unlimited AI Chat & Snap Solve',
                ),
                const SizedBox(height: 16),
                const _BenefitRow(
                  icon: Icons.style_outlined,
                  text: 'Unlimited Quizzes, Summaries & Flashcards',
                ),
                const SizedBox(height: 16),
                const _BenefitRow(
                  icon: Icons.insights_outlined,
                  text: 'Smart Study Plans & Analytics',
                ),

                const Spacer(flex: 2),

                // ── PRICING CARDS ──
                Row(
                  children: [
                    Expanded(
                      child: _LightPricingCard(
                        planName: 'Yearly',
                        price: yearlyPrice,
                        period: '/year',
                        subtitle: yearlyMonthly,
                        badgeText: 'BEST VALUE',
                        isSelected: _isYearlySelected,
                        onTap: () => setState(() => _isYearlySelected = true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LightPricingCard(
                        planName: 'Weekly',
                        price: weeklyPrice,
                        period: '/week',
                        isSelected: !_isYearlySelected,
                        onTap: () => setState(() => _isYearlySelected = false),
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 2),

                // ── CTA ──
                TapScale(
                  scaleDown: 0.96,
                  onTap: purchaseState.isLoading ? null : _onPurchaseTap,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: purchaseState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isYearlySelected ? 'Start 3-Day Free Trial' : 'Get Kapsa Pro',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── FOOTER ──
                Center(
                  child: GestureDetector(
                    onTap: _onRestoreTap,
                    child: const Text(
                      'Restore Purchases',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _isYearlySelected
                        ? '3-day free trial \u00b7 Cancel anytime'
                        : 'Cancel anytime \u00b7 No commitment',
                    style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 12),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => context.push(Routes.terms),
                        child: const Text(
                          'Terms',
                          style: TextStyle(
                            color: Color(0xFFD1D5DB),
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFFD1D5DB),
                          ),
                        ),
                      ),
                      const Text(
                        ' \u00b7 ',
                        style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 11),
                      ),
                      GestureDetector(
                        onTap: () => context.push(Routes.privacy),
                        child: const Text(
                          'Privacy',
                          style: TextStyle(
                            color: Color(0xFFD1D5DB),
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFFD1D5DB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Benefit Row — Light theme with green accent
// ═══════════════════════════════════════════════════════════════════════════════

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF10B981), size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF374151),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
        const Icon(Icons.check_circle, size: 20, color: Color(0xFF10B981)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Light Pricing Card — replaces dark PricingCard
// ═══════════════════════════════════════════════════════════════════════════════

class _LightPricingCard extends StatelessWidget {
  final String planName;
  final String price;
  final String period;
  final String? subtitle;
  final String? badgeText;
  final bool isSelected;
  final VoidCallback? onTap;

  const _LightPricingCard({
    required this.planName,
    required this.price,
    required this.period,
    this.subtitle,
    this.badgeText,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            height: isSelected ? 148 : 136,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                    : const Color(0xFFE5E7EB),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    planName,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: isSelected
                          ? const Color(0xFF374151)
                          : const Color(0xFF9CA3AF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: isSelected
                              ? const Color(0xFF111827)
                              : const Color(0xFF6B7280),
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        period,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Badge
          if (badgeText != null)
            Positioned(
              top: -11,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    badgeText!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

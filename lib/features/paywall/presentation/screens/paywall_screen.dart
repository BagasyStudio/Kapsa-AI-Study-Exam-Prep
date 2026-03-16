import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/providers/revenue_cat_provider.dart';
import '../../../../core/services/revenue_cat_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/pricing_card.dart';
import '../../../../core/widgets/tap_scale.dart';

/// Paywall / Subscription screen.
///
/// Single-viewport decision screen with immersive dark background,
/// 3 benefit rows, pricing cards, and a strong lime CTA.
/// Integrates with RevenueCat for real in-app purchases.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isYearlySelected = true;

  /// Whether the user is currently logged in.
  bool get _isLoggedIn =>
      Supabase.instance.client.auth.currentSession != null;

  /// Dismiss the paywall — navigate to login if unauthenticated, home if logged in.
  void _dismiss() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // Coming from onboarding (no route to pop back to) → mark onboarding
      // as complete so GoRouter redirect won't send us back there.
      ref.read(hasSeenOnboardingProvider.notifier).state = true;
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
      return current.weekly ?? current.getPackage(RevenueCatService.weeklyProductId);
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

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // 1. TOP BAR — Close button + KAPSA PRO pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TapScale(
                    onTap: _dismiss,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.immersiveCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.immersiveBorder),
                      ),
                      child: const Icon(Icons.close, color: Colors.white70, size: 20),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: Color(0xFFFBBF24)),
                        SizedBox(width: 6),
                        Text(
                          'KAPSA PRO',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Spacer pushes content down; Expanded below distributes space
              const Spacer(flex: 2),

              // 2. HEADLINE
              const Text(
                'Unlock Your\nFull Potential',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),

              const SizedBox(height: 28),

              // 3. BENEFITS — 3 compact rows
              const _BenefitRow(
                icon: Icons.chat_bubble_outline,
                text: 'Unlimited AI Chat & Snap Solve',
              ),
              const SizedBox(height: 14),
              const _BenefitRow(
                icon: Icons.style_outlined,
                text: 'Unlimited Quizzes, Summaries & Flashcards',
              ),
              const SizedBox(height: 14),
              const _BenefitRow(
                icon: Icons.insights_outlined,
                text: 'Smart Study Plans & Analytics',
              ),

              const Spacer(flex: 2),

              // 4. PRICING CARDS
              Row(
                children: [
                  Expanded(
                    child: PricingCard(
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
                    child: PricingCard(
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

              // 5. CTA — Lime button, strongest visual element
              TapScale(
                scaleDown: 0.96,
                onTap: purchaseState.isLoading ? null : _onPurchaseTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.ctaLime,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ctaLime.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: purchaseState.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.ctaLimeText,
                            ),
                          )
                        : Text(
                            _isYearlySelected ? 'Start 3-Day Free Trial' : 'Get Kapsa Pro',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ctaLimeText,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 6. MICRO FOOTER
              Center(
                child: GestureDetector(
                  onTap: _onRestoreTap,
                  child: const Text(
                    'Restore Purchases',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white38,
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
                  style: const TextStyle(color: Colors.white30, fontSize: 12),
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
                          color: Colors.white24,
                          fontSize: 11,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white24,
                        ),
                      ),
                    ),
                    const Text(
                      ' \u00b7 ',
                      style: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                    GestureDetector(
                      onTap: () => context.push(Routes.privacy),
                      child: const Text(
                        'Privacy',
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: 11,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white24,
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
    );
  }
}

/// Compact benefit row with lime icon, text, and checkmark.
class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.ctaLime.withValues(alpha: 0.8), size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
        Icon(Icons.check_circle, size: 18, color: AppColors.ctaLime.withValues(alpha: 0.7)),
      ],
    );
  }
}

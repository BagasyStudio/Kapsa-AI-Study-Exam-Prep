import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/providers/revenue_cat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/subscription_repository.dart';
import '../widgets/ai_consent_dialog.dart';

/// Provider for [SubscriptionRepository].
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(Supabase.instance.client);
});

/// Whether the current user is a Pro subscriber.
///
/// Uses RevenueCat as source of truth. Falls back to Supabase
/// if RevenueCat is unavailable (e.g. no network).
final isProProvider = FutureProvider.autoDispose<bool>((ref) async {
  // RevenueCat: source of truth for paid subscribers
  try {
    final rcPro = await ref.watch(revenueCatProProvider.future);
    if (rcPro) return true;
  } catch (e) {
    debugPrint('Subscription: RevenueCat check failed: $e');
  }

  // Supabase: admin override (pro_override) or cached is_pro
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return ref.read(subscriptionRepositoryProvider).getIsPro(user.id);
});

/// Remaining uses for a specific feature.
///
/// Uses a record ({String userId, String feature}) to avoid creating
/// the Future inline in FutureBuilder (which would recreate on every rebuild).
final remainingUsesProvider = FutureProvider.autoDispose
    .family<int, ({String userId, String feature})>((ref, params) async {
  return ref
      .read(subscriptionRepositoryProvider)
      .getRemainingUses(params.userId, params.feature);
});

/// Daily usage map for the current user.
final dailyUsageProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  return ref.read(subscriptionRepositoryProvider).getDailyUsage(user.id);
});

/// Remaining credits for free users today.
final remainingCreditsProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return ref.read(subscriptionRepositoryProvider).getRemainingCredits(user.id);
});

/// Credits consumed today.
final creditsUsedTodayProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return ref
      .read(subscriptionRepositoryProvider)
      .getCreditsUsedToday(user.id);
});

/// Cached AI consent state so we don't query the DB on every feature use.
/// `null` means not yet loaded; `true`/`false` reflects the DB value.
final aiConsentCacheProvider = StateProvider<bool?>((ref) => null);

/// Helper to check feature access and show paywall if blocked.
///
/// Also checks AI consent before allowing any AI feature.
/// Returns true if the user can proceed, false if blocked.
Future<bool> checkFeatureAccess({
  required WidgetRef ref,
  required String feature,
  required BuildContext context,
}) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return false;

  // ── AI Consent Check ──
  var hasConsent = ref.read(aiConsentCacheProvider);

  // First time: load from DB
  if (hasConsent == null) {
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('ai_consent_accepted')
          .eq('id', user.id)
          .maybeSingle();
      hasConsent = profile?['ai_consent_accepted'] as bool? ?? false;
      ref.read(aiConsentCacheProvider.notifier).state = hasConsent;
    } catch (e) {
      debugPrint('SubscriptionProvider: consent check failed: $e');
      hasConsent = false;
    }
  }

  // If no consent yet, show the dialog
  if (!hasConsent && context.mounted) {
    final accepted = await AiConsentDialog.show(context);
    if (accepted) {
      // Save consent to DB
      await Supabase.instance.client.from('profiles').update({
        'ai_consent_accepted': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      ref.read(aiConsentCacheProvider.notifier).state = true;
    } else {
      return false;
    }
  }

  // ── Subscription / Usage Check ──
  final canUse = await ref
      .read(subscriptionRepositoryProvider)
      .checkCanUseFeature(user.id, feature);

  if (!canUse) {
    if (context.mounted) {
      context.push(Routes.paywall);
    }
    return false;
  }

  return canUse;
}

/// Refresh usage caches after a successful action.
///
/// Usage is now recorded server-side by edge functions to prevent
/// bypass. This only invalidates local caches so the UI updates.
Future<void> recordFeatureUsage({
  required WidgetRef ref,
  required String feature,
}) async {
  ref.invalidate(dailyUsageProvider);
  ref.invalidate(remainingCreditsProvider);
  ref.invalidate(creditsUsedTodayProvider);
}

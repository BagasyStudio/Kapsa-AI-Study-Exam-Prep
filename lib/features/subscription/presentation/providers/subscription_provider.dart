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
  // Try RevenueCat first (source of truth)
  try {
    final rcPro = await ref.watch(revenueCatProProvider.future);
    return rcPro;
  } catch (_) {
    // Fallback to Supabase
    final user = ref.watch(currentUserProvider);
    if (user == null) return false;
    return ref.read(subscriptionRepositoryProvider).getIsPro(user.id);
  }
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
    } catch (_) {
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

  if (!canUse && context.mounted) {
    context.push(Routes.paywall);
    return false;
  }

  return true;
}

/// Record feature usage after a successful action.
///
/// Tracks usage for both free and Pro users to enforce
/// daily limits and prevent API abuse.
Future<void> recordFeatureUsage({
  required WidgetRef ref,
  required String feature,
}) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return;

  await ref.read(subscriptionRepositoryProvider).recordUsage(user.id, feature);
  ref.invalidate(dailyUsageProvider);
}

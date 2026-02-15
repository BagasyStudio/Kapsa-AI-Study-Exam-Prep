import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/providers/revenue_cat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/subscription_repository.dart';

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

/// Daily usage map for the current user.
final dailyUsageProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  return ref.read(subscriptionRepositoryProvider).getDailyUsage(user.id);
});

/// Helper to check feature access and show paywall if blocked.
///
/// Returns true if the user can proceed, false if blocked.
/// If blocked, navigates to the paywall screen.
Future<bool> checkFeatureAccess({
  required WidgetRef ref,
  required String feature,
  required BuildContext context,
}) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return false;

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

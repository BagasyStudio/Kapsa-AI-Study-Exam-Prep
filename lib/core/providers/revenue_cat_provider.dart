import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/revenue_cat_service.dart';

/// Singleton provider for [RevenueCatService].
final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService(Supabase.instance.client);
});

/// Whether the current user has an active Pro subscription via RevenueCat.
///
/// This is the source of truth for subscription status.
/// Auto-disposes to refresh when re-entering screens.
final revenueCatProProvider = FutureProvider.autoDispose<bool>((ref) async {
  final service = ref.read(revenueCatServiceProvider);
  return service.isPro();
});

/// Available offerings from RevenueCat (products configured in dashboard).
///
/// Returns null if no offerings exist or on error.
final offeringsProvider = FutureProvider.autoDispose<Offerings?>((ref) async {
  final service = ref.read(revenueCatServiceProvider);
  return service.getOfferings();
});

/// State notifier for purchase loading state.
///
/// Tracks whether a purchase is currently in progress
/// to show loading indicators in the UI.
class PurchaseState {
  final bool isLoading;
  final String? error;

  const PurchaseState({this.isLoading = false, this.error});

  PurchaseState copyWith({bool? isLoading, String? error}) {
    return PurchaseState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final RevenueCatService _service;
  final Ref _ref;

  PurchaseNotifier(this._service, this._ref) : super(const PurchaseState());

  /// Purchase a package and update state.
  Future<bool> purchase(Package package) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _service.purchasePackage(package);
      state = state.copyWith(isLoading: false);
      if (success) {
        // Invalidate pro status so all widgets refresh
        _ref.invalidate(revenueCatProProvider);
      }
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Restore purchases and update state.
  Future<bool> restore() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _service.restorePurchases();
      state = state.copyWith(isLoading: false);
      if (success) {
        _ref.invalidate(revenueCatProProvider);
      }
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

/// Provider for purchase actions (buy + restore) with loading state.
final purchaseNotifierProvider =
    StateNotifierProvider<PurchaseNotifier, PurchaseState>((ref) {
  final service = ref.read(revenueCatServiceProvider);
  return PurchaseNotifier(service, ref);
});

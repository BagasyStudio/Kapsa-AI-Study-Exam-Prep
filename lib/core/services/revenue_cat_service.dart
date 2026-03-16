import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

/// Centralized service for RevenueCat in-app purchase management.
///
/// Handles initialization, purchase flow, restore, and entitlement checks.
/// Syncs subscription status with Supabase `profiles.is_pro`.
class RevenueCatService {
  static const String _entitlementId = 'pro';

  /// Product IDs matching App Store Connect configuration.
  static const String weeklyProductId = 'kapsa_pro_weekly';
  static const String yearlyProductId = 'kapsa_pro_annual';

  /// RevenueCat API Key — injected via dart-define at build time.
  static const String _apiKey = Env.revenueCatApiKey;

  final SupabaseClient _supabase;

  RevenueCatService(this._supabase);

  /// Initialize RevenueCat SDK.
  ///
  /// Must be called once at app startup, after Supabase is initialized.
  /// Sets the Supabase user ID as the RevenueCat app user ID for
  /// cross-platform subscription tracking.
  Future<void> initialize() async {
    final configuration = PurchasesConfiguration(_apiKey);

    // Set Supabase user ID as RevenueCat app user ID
    final user = _supabase.auth.currentUser;
    if (user != null) {
      configuration.appUserID = user.id;
    }

    await Purchases.configure(configuration);

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    // Listen for customer info changes (e.g. subscription renewals/expirations)
    Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
  }

  /// Log in to RevenueCat with the Supabase user ID.
  ///
  /// Call this after Supabase auth sign-in.
  /// Silently fails on platforms without RevenueCat support (e.g. web).
  Future<void> login(String userId) async {
    try {
      await Purchases.logIn(userId);
      await _syncProStatus();
    } on MissingPluginException catch (_) {
      // RevenueCat not available on this platform (web)
    }
  }

  /// Log out from RevenueCat.
  ///
  /// Call this when the user signs out of Supabase.
  /// Silently fails on platforms without RevenueCat support (e.g. web).
  Future<void> logout() async {
    try {
      await Purchases.logOut();
    } on MissingPluginException catch (_) {
      // RevenueCat not available on this platform (web)
    }
  }

  /// Check if the user currently has an active "pro" entitlement.
  Future<bool> isPro() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(_entitlementId);
    } catch (_) {
      return false;
    }
  }

  /// Fetch available offerings (products/packages).
  ///
  /// Returns null if no offerings are configured or on error.
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  /// Purchase a specific package.
  ///
  /// Returns true if purchase was successful, false otherwise.
  /// After successful purchase, syncs is_pro to Supabase.
  Future<bool> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      final isPro =
          result.entitlements.active.containsKey(_entitlementId);
      if (isPro) {
        await _setSupabasePro(true);
      }
      return isPro;
    } catch (e) {
      // PurchasesErrorCode.purchaseCancelledError is normal user cancellation
      if (e is PlatformException) {
        // User cancelled — not an error
        return false;
      }
      rethrow;
    }
  }

  /// Restore previous purchases.
  ///
  /// Returns true if pro entitlement was restored.
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isPro =
          customerInfo.entitlements.active.containsKey(_entitlementId);
      await _setSupabasePro(isPro);
      return isPro;
    } catch (_) {
      return false;
    }
  }

  /// Callback for RevenueCat customer info updates.
  ///
  /// Triggered when subscription status changes (renewal, expiration, etc.)
  void _onCustomerInfoUpdated(CustomerInfo info) {
    final isPro = info.entitlements.active.containsKey(_entitlementId);
    _setSupabasePro(isPro);
  }

  /// Sync the subscription status with Supabase.
  Future<void> _syncProStatus() async {
    final isPro = await this.isPro();
    await _setSupabasePro(isPro);
  }

  /// Update `profiles.is_pro` in Supabase.
  Future<void> _setSupabasePro(bool isPro) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('profiles').update({
        'is_pro': isPro,
      }).eq('id', user.id);
    } catch (_) {
      // Silent fail — will retry on next sync
    }
  }
}

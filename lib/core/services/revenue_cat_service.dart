import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';
import 'notification_service.dart';

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

    // Sync Pro status on launch — catches expired subscriptions that
    // expired while the app was closed (listener wouldn't have fired).
    if (user != null) {
      _syncProStatus().catchError((e) {
        debugPrint('RevenueCatService: launch sync failed: $e');
      });
    }
  }

  /// Log in to RevenueCat with the Supabase user ID.
  ///
  /// Call this after Supabase auth sign-in/sign-up.
  /// If the user purchased while anonymous (e.g. during onboarding before
  /// creating an account), `Purchases.logIn()` transfers the anonymous
  /// purchases to the identified user. We also call `restorePurchases()`
  /// to ensure Apple/Google receipts are fully synced.
  Future<void> login(String userId) async {
    try {
      final result = await Purchases.logIn(userId);
      // Check if the anonymous user had an active subscription
      final hadPro =
          result.customerInfo.entitlements.active.containsKey(_entitlementId);
      if (hadPro) {
        debugPrint('RevenueCatService: transferred anonymous Pro to user $userId');
      }
      // Always restore to catch any App Store/Play Store receipts
      await Purchases.restorePurchases();
      await _syncProStatus();
    } on MissingPluginException catch (e) {
      debugPrint('RevenueCatService: login failed (no plugin): $e');
    } catch (e) {
      debugPrint('RevenueCatService: login/restore failed: $e');
      // Still try to sync whatever state we have
      try { await _syncProStatus(); } catch (e) { debugPrint('RevenueCatService: sync fallback failed: $e'); }
    }
  }

  /// Log out from RevenueCat.
  ///
  /// Call this when the user signs out of Supabase.
  /// Silently fails on platforms without RevenueCat support (e.g. web).
  Future<void> logout() async {
    try {
      await Purchases.logOut();
    } on MissingPluginException catch (e) {
      // RevenueCat not available on this platform (web)
      debugPrint('RevenueCatService: logout failed: $e');
    }
  }

  /// Check if the user currently has an active "pro" entitlement.
  Future<bool> isPro() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(_entitlementId);
    } catch (e) {
      debugPrint('RevenueCatService: isPro check failed: $e');
      return false;
    }
  }

  /// Fetch available offerings (products/packages).
  ///
  /// Returns null if no offerings are configured or on error.
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('RevenueCatService: getOfferings failed: $e');
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
        // Schedule trial engagement notifications if this is a trial
        _scheduleTrialNotificationsIfNeeded(package);
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

  /// Schedule trial notifications if the purchased package has an intro offer.
  static void _scheduleTrialNotificationsIfNeeded(Package package) {
    try {
      final intro = package.storeProduct.introductoryPrice;
      if (intro == null) return; // No trial

      // Detect trial days from period
      final trialDays = intro.periodUnit == PeriodUnit.day
          ? intro.periodNumberOfUnits
          : intro.periodUnit == PeriodUnit.week
              ? intro.periodNumberOfUnits * 7
              : 3; // fallback

      NotificationService.scheduleTrialNotifications(
        trialDays: trialDays,
        strings: const TrialNotifStrings(
          day0Title: 'Your study plan is ready!',
          day0Body: 'Generate your first flashcards now',
          day1Title: 'Did you know?',
          day1Body: 'Students who use flashcards score 23% higher. Try generating a quiz!',
          day2Title: 'Have you tried Snap & Solve?',
          day2Body: 'Take a photo of any problem and get a step-by-step solution',
          lastDayTitle: 'Last day of your trial!',
          lastDayBody: 'Make the most of it — generate flashcards, quizzes, and summaries',
          twoDaysLeftTitle: '2 days left on your trial',
          twoDaysLeftBody: "Don't miss out — explore all the AI tools before it ends",
        ),
      );
    } catch (e) {
      debugPrint('RevenueCatService: trial notifications failed: $e');
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
    } catch (e) {
      debugPrint('RevenueCatService: restorePurchases failed: $e');
      return false;
    }
  }

  /// Callback for RevenueCat customer info updates.
  ///
  /// Triggered when subscription status changes (renewal, expiration, etc.)
  void _onCustomerInfoUpdated(CustomerInfo info) {
    final isPro = info.entitlements.active.containsKey(_entitlementId);
    _setSupabasePro(isPro).catchError((e) {
      debugPrint('RevenueCatService: customerInfo sync failed: $e');
    });
  }

  /// Sync the subscription status with Supabase.
  Future<void> _syncProStatus() async {
    final isPro = await this.isPro();
    await _setSupabasePro(isPro);
  }

  /// Update `profiles.is_pro` in Supabase.
  Future<void> _setSupabasePro(bool isPro) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (isPro) {
        debugPrint('RevenueCatService: user has Pro but no Supabase account yet — will sync on login');
      }
      return;
    }

    try {
      await _supabase.from('profiles').update({
        'is_pro': isPro,
      }).eq('id', user.id);
    } catch (e) {
      // Silent fail — will retry on next sync
      debugPrint('RevenueCatService: setSupabasePro failed: $e');
    }
  }
}

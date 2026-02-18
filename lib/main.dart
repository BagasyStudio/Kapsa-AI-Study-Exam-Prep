import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/env.dart';
import 'core/navigation/app_router.dart';
import 'core/providers/error_observer.dart';
import 'core/providers/revenue_cat_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/revenue_cat_service.dart';
import 'core/services/sound_service.dart';
import 'core/utils/error_handler.dart';

void main() {
  AppErrorHandler.init(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Supabase (keys from environment / dart-define)
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );

    // Skip native-only plugins on web
    RevenueCatService? revenueCat;
    if (!kIsWeb) {
      // Initialize local notifications
      await NotificationService.initialize();

      // Initialize sound effects
      await SoundService.init();

      // Initialize RevenueCat (single instance shared via provider override)
      revenueCat = RevenueCatService(Supabase.instance.client);
      await revenueCat.initialize();

      // If user is already signed in, log in to RevenueCat
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        await revenueCat.login(currentUser.id);
      }
    }

    // Check onboarding flag
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    // Force portrait orientation for iOS
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Light status bar icons
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    runApp(
      ProviderScope(
        observers: [AppProviderObserver()],
        overrides: [
          hasSeenOnboardingProvider.overrideWith(
            (ref) => hasSeenOnboarding,
          ),
          // Share the pre-initialized RevenueCat instance with all providers
          if (revenueCat != null)
            revenueCatServiceProvider.overrideWithValue(revenueCat),
        ],
        child: const KapsaApp(),
      ),
    );
  });
}

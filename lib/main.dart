import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/navigation/app_router.dart';
import 'core/services/revenue_cat_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://uudooipqcmtmyscessjq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV1ZG9vaXBxY210bXlzY2Vzc2pxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExMDE0MzAsImV4cCI6MjA4NjY3NzQzMH0.cHTmBa5wDmMbIURHAz_0WXMK9luz98RWejmSAezXVTU',
  );

  // Initialize RevenueCat
  final revenueCat = RevenueCatService(Supabase.instance.client);
  await revenueCat.initialize();

  // If user is already signed in, log in to RevenueCat
  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser != null) {
    await revenueCat.login(currentUser.id);
  }

  // Check onboarding flag
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  // Force portrait orientation for iOS
  SystemChrome.setPreferredOrientations([
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
      overrides: [
        hasSeenOnboardingProvider.overrideWith(
          (ref) => hasSeenOnboarding,
        ),
      ],
      child: const KapsaApp(),
    ),
  );
}

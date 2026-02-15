/// Environment configuration for Kapsa.
///
/// Values are injected at build time via `--dart-define`.
/// Fallback values are used for local development only.
///
/// Production builds (Codemagic) should ALWAYS pass:
/// ```
/// flutter build ipa --dart-define=SUPABASE_URL=... \
///   --dart-define=SUPABASE_ANON_KEY=... \
///   --dart-define=REVENUECAT_API_KEY=...
/// ```
class Env {
  Env._();

  /// Supabase project URL.
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://uudooipqcmtmyscessjq.supabase.co',
  );

  /// Supabase anonymous (public) API key.
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV1ZG9vaXBxY210bXlzY2Vzc2pxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExMDE0MzAsImV4cCI6MjA4NjY3NzQzMH0.cHTmBa5wDmMbIURHAz_0WXMK9luz98RWejmSAezXVTU',
  );

  /// RevenueCat public API key (iOS).
  static const revenueCatApiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
    defaultValue: 'appl_awHRXyxfHYNdWuuvSCJlBSAAFgF',
  );
}

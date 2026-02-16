import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_functions.dart';

/// Global provider for the Supabase client instance.
///
/// Initialized in main.dart via [Supabase.initialize].
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for the Edge Functions wrapper with auto-refresh.
///
/// Ensures the JWT access token is fresh before every
/// Edge Function invocation.
final supabaseFunctionsProvider = Provider<SupabaseFunctions>((ref) {
  return SupabaseFunctions(ref.watch(supabaseClientProvider));
});

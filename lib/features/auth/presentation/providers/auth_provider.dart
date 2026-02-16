import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/auth_repository.dart';

/// Provider for the auth repository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

/// Stream of auth state changes — used to trigger provider recalculation.
///
/// Filtered to only emit on signedIn / signedOut. Without this filter,
/// every tokenRefreshed event (fired by refreshSession()) would cascade
/// through currentUserProvider → all downstream providers, causing
/// all home screen widgets to re-fetch and flicker.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges.where((state) =>
      state.event == AuthChangeEvent.signedIn ||
      state.event == AuthChangeEvent.signedOut);
});

/// The currently authenticated user (null = not logged in).
///
/// Automatically recalculates when auth state changes.
final currentUserProvider = Provider<User?>((ref) {
  // Watch the auth state stream to trigger recalculation
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).currentUser;
});

/// Whether the user is currently authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

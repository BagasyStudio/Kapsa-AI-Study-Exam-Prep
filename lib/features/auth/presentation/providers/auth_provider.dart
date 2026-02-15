import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/auth_repository.dart';

/// Provider for the auth repository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

/// Stream of auth state changes — used to trigger router redirects.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
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

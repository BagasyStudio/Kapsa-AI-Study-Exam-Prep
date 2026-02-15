import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository handling all authentication operations via Supabase Auth.
class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  /// Stream of auth state changes (sign in, sign out, token refresh).
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Current active session (null if not authenticated).
  Session? get currentSession => _client.auth.currentSession;

  /// Current authenticated user (null if not authenticated).
  User? get currentUser => _client.auth.currentUser;

  /// Register a new user with email + password.
  ///
  /// Optionally pass [fullName] which gets stored in user_metadata
  /// and picked up by the profiles trigger.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  /// Sign in with email + password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Send a password reset email.
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Delete the current user's account and all associated data.
  ///
  /// Calls the delete-user-data Edge Function which handles
  /// cascading deletion of all user data before removing the auth user.
  Future<void> deleteAccount() async {
    await _client.functions.invoke('delete-user-data');
    await _client.auth.signOut();
  }
}

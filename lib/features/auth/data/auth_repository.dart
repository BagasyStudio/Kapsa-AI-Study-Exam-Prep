import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/revenue_cat_service.dart';
import '../../../core/services/supabase_functions.dart';

/// Repository handling all authentication operations via Supabase Auth.
class AuthRepository {
  final SupabaseClient _client;
  final SupabaseFunctions _functions;
  final RevenueCatService _revenueCat;

  AuthRepository(this._client, this._functions)
      : _revenueCat = RevenueCatService(_client);

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
  /// Also logs in to RevenueCat for subscription tracking.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
    // Sync RevenueCat with the new user
    if (response.user != null) {
      await _revenueCat.login(response.user!.id);
    }
    return response;
  }

  /// Sign in with email + password.
  ///
  /// Also logs in to RevenueCat for subscription tracking.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    // Sync RevenueCat with the authenticated user
    if (response.user != null) {
      await _revenueCat.login(response.user!.id);
    }
    return response;
  }

  /// Sign out the current user.
  ///
  /// Also logs out from RevenueCat.
  Future<void> signOut() async {
    await _revenueCat.logout();
    await _client.auth.signOut();
  }

  /// Sign in with Apple using native flow + Supabase OAuth.
  ///
  /// Uses the raw nonce approach: generates a nonce, passes it to Apple,
  /// then exchanges the Apple ID token with Supabase.
  /// Also syncs RevenueCat after successful sign-in.
  Future<AuthResponse> signInWithApple() async {
    // Generate a random nonce for security
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    // Request Apple credentials
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception('Apple Sign-In failed: no identity token received');
    }

    // Exchange Apple token with Supabase
    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    // Sync RevenueCat
    if (response.user != null) {
      await _revenueCat.login(response.user!.id);

      // If Apple provided the name (first sign-in only), update profile
      final givenName = credential.givenName;
      final familyName = credential.familyName;
      if (givenName != null || familyName != null) {
        final fullName = [givenName, familyName]
            .where((n) => n != null && n.isNotEmpty)
            .join(' ');
        if (fullName.isNotEmpty) {
          await _client.auth.updateUser(
            UserAttributes(data: {'full_name': fullName}),
          );
        }
      }
    }

    return response;
  }

  /// Generate a cryptographically secure random nonce.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
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
    await _functions.invoke('delete-user-data');
    await _client.auth.signOut();
  }
}

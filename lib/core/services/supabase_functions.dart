import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exception thrown when the session cannot be refreshed.
///
/// Indicates the user must sign in again (refresh token is invalid
/// or missing).
class SessionExpiredException implements Exception {
  final String message;
  const SessionExpiredException(
      [this.message = 'Session expired. Please sign in again.']);

  @override
  String toString() => 'SessionExpiredException: $message';
}

/// Wrapper around Supabase Edge Function calls with retry on 401.
///
/// The Supabase Flutter SDK's internal [AuthHttpClient] already
/// auto-refreshes expired tokens before every HTTP request
/// (including `functions.invoke()`). This wrapper does NOT
/// attempt its own token refresh — it simply:
///
/// 1. Checks that a user is logged in (fast, no network call).
/// 2. Delegates to `_client.functions.invoke()` (SDK handles auth).
/// 3. If the call fails with 401, retries ONCE (handles rare race
///    conditions where the token expired between SDK refresh and
///    Edge Function processing).
class SupabaseFunctions {
  final SupabaseClient _client;

  SupabaseFunctions(this._client);

  /// Invoke an Edge Function.
  ///
  /// Parameters mirror [FunctionsClient.invoke] exactly.
  /// Throws [SessionExpiredException] only if there is truly no
  /// logged-in user.
  Future<FunctionResponse> invoke(
    String functionName, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    HttpMethod method = HttpMethod.post,
  }) async {
    // Quick check: is there a user at all?
    // currentUser persists through token refresh cycles, so this
    // is a reliable indicator of "logged in".
    if (_client.auth.currentUser == null) {
      throw const SessionExpiredException();
    }

    try {
      // The SDK's AuthHttpClient automatically refreshes the
      // access token if it's expired before sending the request.
      // Timeout prevents infinite waiting if Edge Function hangs.
      return await _client.functions
          .invoke(
            functionName,
            headers: headers,
            body: body,
            method: method,
          )
          .timeout(const Duration(seconds: 120));
    } on TimeoutException {
      throw Exception(
        'The AI is taking too long to respond. Please try again.',
      );
    } on FunctionException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[SupabaseFunctions] $functionName failed: '
          'status=${e.status}, details=${e.details}',
        );
      }

      // 401 → token might have expired in a race condition.
      // Try refreshing manually and retry once.
      if (e.status == 401) {
        try {
          await _client.auth.refreshSession();
        } catch (refreshError) {
          if (kDebugMode) {
            debugPrint(
              '[SupabaseFunctions] Token refresh failed: $refreshError',
            );
          }
          // Only NOW do we know the session is truly gone.
          throw const SessionExpiredException();
        }
        // Retry the call with the fresh token.
        return _client.functions.invoke(
          functionName,
          headers: headers,
          body: body,
          method: method,
        );
      }
      rethrow;
    }
  }
}

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
/// Flow:
/// 1. Check that a user is logged in (fast, no network call).
/// 2. Delegate to `_client.functions.invoke()` (SDK handles auth).
/// 3. If 401: refresh session + retry once.
/// 4. If retry also 401: the problem is server-side (missing secrets,
///    misconfigured edge function) — rethrow as FunctionException,
///    NOT SessionExpiredException.
class SupabaseFunctions {
  final SupabaseClient _client;

  SupabaseFunctions(this._client);

  /// Invoke an Edge Function.
  ///
  /// Throws [SessionExpiredException] only when:
  /// - No logged-in user exists, OR
  /// - Token refresh explicitly fails (refresh token invalid/expired)
  ///
  /// Server-side 401s (missing SERVICE_ROLE_KEY, edge function auth
  /// issues) are rethrown as [FunctionException] so the error handler
  /// shows "AI service error" instead of "session expired".
  Future<FunctionResponse> invoke(
    String functionName, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    HttpMethod method = HttpMethod.post,
  }) async {
    // Quick check: is there a user at all?
    if (_client.auth.currentUser == null) {
      debugPrint('[SupabaseFunctions] No currentUser — session expired');
      throw const SessionExpiredException();
    }

    try {
      return await _client.functions
          .invoke(
            functionName,
            headers: headers,
            body: body,
            method: method,
          )
          .timeout(const Duration(seconds: 180));
    } on TimeoutException {
      throw Exception(
        'The AI is taking too long to respond. Please try again.',
      );
    } on FunctionException catch (e) {
      debugPrint(
        '[SupabaseFunctions] $functionName FAILED: '
        'status=${e.status}, '
        'details=${e.details} (${e.details.runtimeType}), '
        'reasonPhrase=${e.reasonPhrase}',
      );

      if (e.status == 401) {
        // ── Step 1: Try refreshing the session ──
        debugPrint(
          '[SupabaseFunctions] Got 401 — refreshing session...',
        );
        bool refreshSucceeded = false;
        try {
          await _client.auth.refreshSession();
          refreshSucceeded = true;
          debugPrint(
            '[SupabaseFunctions] Session refresh OK — retrying...',
          );
        } catch (refreshError) {
          debugPrint(
            '[SupabaseFunctions] Session refresh FAILED: $refreshError',
          );
          // Refresh token is truly invalid → user must re-login
          throw const SessionExpiredException();
        }

        // ── Step 2: Retry with fresh token ──
        if (refreshSucceeded) {
          try {
            return await _client.functions
                .invoke(
                  functionName,
                  headers: headers,
                  body: body,
                  method: method,
                )
                .timeout(const Duration(seconds: 180));
          } on FunctionException catch (retryError) {
            // Retry ALSO got an error. Since we just refreshed
            // successfully, the problem is NOT the user's session —
            // it's a server-side issue (missing secrets, edge function
            // bug, etc.). Rethrow as FunctionException so the error
            // handler shows "AI service error" not "session expired".
            debugPrint(
              '[SupabaseFunctions] Retry ALSO failed: '
              'status=${retryError.status}, '
              'details=${retryError.details} '
              '(${retryError.details.runtimeType})',
            );
            rethrow;
          }
        }
      }
      rethrow;
    }
  }
}

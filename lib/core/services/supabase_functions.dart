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

    // Pre-emptive token refresh if close to expiry (within 2 min).
    await _ensureFreshToken();

    // Ensure the access token is explicitly set in headers.
    // The Supabase SDK should do this automatically, but in some edge
    // cases (fresh signup, rapid token refresh) the internal token
    // may not be in sync. Explicitly passing it guarantees the gateway
    // receives a valid JWT.
    final accessToken = _client.auth.currentSession?.accessToken;
    final mergedHeaders = <String, String>{
      if (headers != null) ...headers,
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };

    try {
      return await _client.functions
          .invoke(
            functionName,
            headers: mergedHeaders,
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

  /// Refresh the JWT if it expires within 2 minutes.
  Future<void> _ensureFreshToken() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return;
      final expiresAt = session.expiresAt;
      if (expiresAt != null) {
        final expiresIn = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000)
            .difference(DateTime.now())
            .inSeconds;
        if (expiresIn < 120) {
          debugPrint('[SupabaseFunctions] Refreshing JWT (expires in ${expiresIn}s)');
          await _client.auth.refreshSession();
        }
      }
    } catch (e) {
      debugPrint('[SupabaseFunctions] Token refresh failed: $e');
      // Continue anyway — the 401 retry logic will handle it
    }
  }
}

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

/// Wrapper around Supabase Edge Function calls that ensures a
/// fresh JWT access token before every invocation.
///
/// The Supabase Flutter SDK auto-refreshes tokens for Postgrest
/// and Realtime, but NOT for `functions.invoke()`. This service
/// fills that gap by proactively refreshing the token when it is
/// about to expire (within [_refreshThreshold] seconds).
class SupabaseFunctions {
  final SupabaseClient _client;

  /// How many seconds before expiry to proactively refresh.
  /// 60 seconds gives comfortable margin for slow networks +
  /// long AI operations (5-30s).
  static const int _refreshThreshold = 60;

  SupabaseFunctions(this._client);

  /// Invoke an Edge Function with automatic token refresh.
  ///
  /// Parameters mirror [FunctionsClient.invoke] exactly.
  Future<FunctionResponse> invoke(
    String functionName, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    HttpMethod method = HttpMethod.post,
  }) async {
    await _ensureFreshToken();
    return _client.functions.invoke(
      functionName,
      headers: headers,
      body: body,
      method: method,
    );
  }

  /// Check if the current access token is expired or about to
  /// expire, and refresh it if needed.
  ///
  /// This does NOT trigger UI rebuilds because:
  /// - authStateProvider filters out tokenRefreshed events
  /// - _AuthStateNotifier in app_router also filters them
  Future<void> _ensureFreshToken() async {
    final session = _client.auth.currentSession;

    // No session at all — user must sign in
    if (session == null) {
      throw const SessionExpiredException();
    }

    // expiresAt is Unix timestamp in seconds (from JWT `exp` claim)
    final expiresAt = session.expiresAt;
    if (expiresAt == null) {
      // No expiry info — try refreshing to be safe
      await _tryRefresh();
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final secondsUntilExpiry = expiresAt - now;

    if (secondsUntilExpiry <= _refreshThreshold) {
      if (kDebugMode) {
        debugPrint(
          '[SupabaseFunctions] Token expires in ${secondsUntilExpiry}s '
          '(threshold: ${_refreshThreshold}s) — refreshing...',
        );
      }
      await _tryRefresh();
    }
  }

  /// Attempt to refresh the session. If it fails, throw
  /// [SessionExpiredException] so callers can handle it.
  Future<void> _tryRefresh() async {
    try {
      await _client.auth.refreshSession();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseFunctions] Token refresh failed: $e');
      }
      throw const SessionExpiredException();
    }
  }
}

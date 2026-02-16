import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized session refresh manager that deduplicates concurrent
/// [refreshSession] calls.
///
/// When multiple repositories need to refresh the auth token before
/// calling Edge Functions, this ensures only one actual refresh happens
/// at a time. Subsequent callers wait for the in-flight refresh rather
/// than starting a new one (which would cause a race condition where
/// concurrent refresh calls invalidate each other's tokens).
class SessionManager {
  static Completer<void>? _refreshCompleter;

  /// Refresh the session token if needed.
  ///
  /// If a refresh is already in-flight, this returns the same Future
  /// so all callers wait for the single refresh to complete.
  static Future<void> refreshIfNeeded(SupabaseClient client) async {
    // If a refresh is already in progress, wait for it
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    // Start a new refresh
    _refreshCompleter = Completer<void>();
    try {
      await client.auth.refreshSession();
      _refreshCompleter!.complete();
    } catch (e) {
      _refreshCompleter!.completeError(e);
    } finally {
      _refreshCompleter = null;
    }
  }
}

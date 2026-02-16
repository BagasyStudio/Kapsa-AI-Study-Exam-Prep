import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Global error handler for Kapsa.
///
/// Catches unhandled exceptions (both sync and async) and displays
/// user-friendly messages instead of crashing.
class AppErrorHandler {
  AppErrorHandler._();

  /// Global navigator key used to show error SnackBars from anywhere.
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// Initialize error handling.
  ///
  /// Wraps [appRunner] with a guarded zone so unhandled async errors
  /// are caught. Also sets [FlutterError.onError] for framework errors.
  static void init(VoidCallback appRunner) {
    // Catch Flutter framework errors (rendering, layout, etc.)
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _logError(details.exception, details.stack);
    };

    // Catch platform dispatcher errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError(error, stack);
      return true;
    };

    // Catch all unhandled async errors
    runZonedGuarded(
      appRunner,
      (error, stack) {
        _logError(error, stack);
      },
    );
  }

  /// Parse an error into a user-friendly message.
  static String friendlyMessage(Object error) {
    final msg = error.toString().toLowerCase();

    // Log the real error for debugging
    if (kDebugMode) {
      debugPrint('[ErrorHandler] Raw error: $error');
    }

    // Network errors
    if (msg.contains('socketexception') ||
        msg.contains('handshakeexception') ||
        msg.contains('clientexception') ||
        msg.contains('network') ||
        msg.contains('connection refused') ||
        msg.contains('no internet')) {
      return 'No internet connection. Check your network and try again.';
    }

    // Timeout errors
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return 'Request timed out. Please try again.';
    }

    // Auth errors
    if (msg.contains('invalid login') || msg.contains('invalid_credentials')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    if (msg.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    // Session expiry — only match specific JWT/token expiry messages
    if (msg.contains('jwt expired') ||
        msg.contains('token is expired') ||
        msg.contains('invalid claim: missing sub claim') ||
        msg.contains('refresh_token_not_found')) {
      return 'Your session has expired. Please sign in again.';
    }

    // Rate limiting
    if (msg.contains('rate limit') || msg.contains('429') || msg.contains('too many')) {
      return 'Too many requests. Please wait a moment and try again.';
    }

    // Edge function errors — check BEFORE generic server errors
    if (msg.contains('functionserror') ||
        msg.contains('functionsrelayhror') ||
        msg.contains('edge function') ||
        msg.contains('functions/v1')) {
      return 'AI service is temporarily unavailable. Please try again.';
    }

    // Server errors
    if (msg.contains('500') || msg.contains('internal server')) {
      return 'Server error. Please try again later.';
    }
    if (msg.contains('502') || msg.contains('503') || msg.contains('504')) {
      return 'Service temporarily unavailable. Please try again.';
    }

    // Generic fallback
    return 'Something went wrong. Please try again.';
  }

  /// Show a user-friendly error SnackBar.
  static void showError(Object error, {BuildContext? context}) {
    final message = friendlyMessage(error);

    // Try to use provided context first, then navigator key
    final ctx = context ?? navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFEF4444),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Log error to console (and future crash reporting service).
  static void _logError(Object error, StackTrace? stack) {
    if (kDebugMode) {
      debugPrint('╔══════════════════════════════════════');
      debugPrint('║ UNHANDLED ERROR');
      debugPrint('║ $error');
      if (stack != null) {
        debugPrint('║ Stack trace:');
        debugPrint('║ $stack');
      }
      debugPrint('╚══════════════════════════════════════');
    }

    // TODO: Send to Sentry/Crashlytics when integrated
    // CrashlyticsService.recordError(error, stack);
  }
}

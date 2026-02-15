import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod observer that logs provider errors.
///
/// Attached to [ProviderScope] in app.dart to catch all provider-level
/// errors (failed FutureProvider, StateNotifier exceptions, etc.)
class AppProviderObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      debugPrint('╔══ PROVIDER ERROR ══════════════════');
      debugPrint('║ Provider: ${provider.name ?? provider.runtimeType}');
      debugPrint('║ Error: $error');
      debugPrint('╚════════════════════════════════════');
    }

    // TODO: Send to crash reporting when integrated
  }
}

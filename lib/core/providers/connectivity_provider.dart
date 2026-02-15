import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streams connectivity status changes.
///
/// Emits `true` when online, `false` when offline.
/// Used by [OfflineBanner] to show/hide the "No connection" indicator.
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    // results is List<ConnectivityResult>
    return results.any((r) => r != ConnectivityResult.none);
  });
});

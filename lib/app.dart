import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/error_handler.dart';
import 'core/widgets/offline_banner.dart';

/// Root widget of the Kapsa app.
///
/// Uses [ConsumerWidget] to access the [goRouterProvider] which
/// handles auth-based redirects via Riverpod.
class KapsaApp extends ConsumerWidget {
  const KapsaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Kapsa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        // Wrap all screens with the offline banner + error handler key
        return Stack(
          children: [
            // The actual app content
            Scaffold(
              key: AppErrorHandler.navigatorKey,
              backgroundColor: Colors.transparent,
              body: child ?? const SizedBox.shrink(),
            ),
            // Offline banner overlays on top
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: OfflineBanner(),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';

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
    );
  }
}

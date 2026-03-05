import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

/// LEON — Operational Fitness OS
/// Entry point.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO(bootstrap): initialise Hive, Supabase, and other services here.
  runApp(
    // ProviderScope is the root of the Riverpod provider tree.
    const ProviderScope(child: LeonApp()),
  );
}

/// Root application widget.
class LeonApp extends ConsumerWidget {
  const LeonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'LEON',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: AppRouter.router,
    );
  }
}

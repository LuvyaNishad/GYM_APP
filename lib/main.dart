import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_colors.dart';
import 'core/providers/local_date_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/workout_session/providers/active_session_provider.dart';
import 'features/workout_session/providers/rest_timer_provider.dart';
import 'features/workout_session/services/notification_service.dart';
import 'services/hive_service.dart';
import 'state/app_providers.dart';

/// LEON — Operational Fitness OS
/// Entry point.
///
/// Bootstrap runs **before** `runApp` so that every Hive box is open by the
/// first frame — [HiveService] exposes synchronous reads, and screens would
/// otherwise race the box opening. Supabase stays deferred; LEON is
/// local-first and nothing needs the network to boot.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  try {
    await HiveService.init();
  } catch (error, stackTrace) {
    // Local storage is not optional — without it the app can't read or write
    // anything, so fail loudly instead of booting into a broken dashboard.
    debugPrint('LEON bootstrap failed: $error\n$stackTrace');
    container.dispose();
    runApp(BootstrapFailureApp(error: error));
    return;
  }

  container.read(appBootstrappedProvider.notifier).markReady();

  runApp(
    // The pre-warmed container carries the bootstrap result into the tree.
    UncontrolledProviderScope(container: container, child: const LeonApp()),
  );
}

/// Root application widget.
class LeonApp extends ConsumerWidget {
  const LeonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `main` marks bootstrap ready before the first frame, so this only
    // guards scopes built without it (widget tests, and any future async
    // bootstrap step that lands after `runApp`).
    final ready = ref.watch(appBootstrappedProvider);

    return MaterialApp.router(
      title: 'AEON',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: ref.watch(routerProvider),
      builder: (BuildContext context, Widget? child) => ready
          ? _WorkoutLifecycleObserver(child: child ?? const SizedBox.shrink())
          : const _BootstrapLoader(),
    );
  }
}

/// Observer monitoring app lifecycle changes to trigger background/lockscreen notifications.
class _WorkoutLifecycleObserver extends ConsumerStatefulWidget {
  const _WorkoutLifecycleObserver({required this.child});
  final Widget child;

  @override
  ConsumerState<_WorkoutLifecycleObserver> createState() =>
      _WorkoutLifecycleObserverState();
}

class _WorkoutLifecycleObserverState
    extends ConsumerState<_WorkoutLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Request notification permissions for Android 13+ and iOS on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifications = ref.read(workoutNotificationServiceProvider);
      notifications.updateAppLifecycleState(
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed,
      );
      notifications.requestPermissions();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final notifs = ref.read(workoutNotificationServiceProvider);
    notifs.updateAppLifecycleState(state);

    if (notifs.isAppInBackground) {
      final session = ref.read(activeSessionProvider);
      final restTimer = ref.read(restTimerProvider);
      ref.read(activeSessionProvider.notifier).persistInBackground();
      // App was minimized to the background
      if (session.isActive) {
        // If rest timer is NOT running, show the active workout progress notification
        if (!restTimer.isRunning) {
          final next = session.nextPendingSet(
            preferredExerciseId: session.expandedExerciseId,
          );
          if (next == null) {
            notifs.cancelAll();
            return;
          }
          notifs.showActiveWorkoutNotification(
            splitName: session.splitName.replaceAll('//', '●'),
            currentExerciseName: next.exercise.name,
            currentSet: next.set.setNumber,
            totalSets: next.exercise.sets.length,
            isWarmup: next.set.isWarmup,
            weightKg: next.set.weightKg,
            reps: next.set.reps,
          );
        } else {
          notifs.cancelActiveWorkoutNotification();
          // Rest started in the foreground has no notification yet. Publish
          // its current wall-clock countdown as soon as the app is hidden.
          ref.read(restTimerProvider.notifier).resyncWithWallClock();
        }
      } else {
        notifs.cancelAll();
      }
    } else if (state == AppLifecycleState.resumed) {
      // Refresh date-dependent screens after crossing midnight while suspended.
      ref.invalidate(localDateProvider);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Minimal splash shown while bootstrap is still in flight.
class _BootstrapLoader extends StatelessWidget {
  const _BootstrapLoader();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.background,
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// Standalone app shown when bootstrap fails.
///
/// Deliberately does not use [ProviderScope] or the router — both may depend on
/// storage that just failed to open.
class BootstrapFailureApp extends StatelessWidget {
  const BootstrapFailureApp({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AEON',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  size: 40,
                ),
                const SizedBox(height: 20),
                Text(
                  'STORAGE UNAVAILABLE',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'LEON could not open its local database, so nothing can be '
                  'logged or read. Restart the app; if this persists, '
                  'reinstalling will reset local storage.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  '$error',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

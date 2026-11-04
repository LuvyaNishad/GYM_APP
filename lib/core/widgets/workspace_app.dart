import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/workout_session/providers/active_session_provider.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../features/workout_session/services/native_rest_service.dart';
import '../../features/workout_session/services/notification_service.dart';
import '../../services/account_workspace_service.dart';
import '../../services/auth_service.dart';
import '../../services/backup_service.dart';
import '../../services/hive_service.dart';
import '../../services/supabase_service.dart';
import '../../state/app_providers.dart';
import '../theme/app_theme.dart';
import '../router/app_router.dart';
import '../constants/app_constants.dart';

/// Entire provider containers are replaced on account changes, including cached
/// providers that only read storage once. No old screen survives an owner switch.
class WorkspaceApp extends StatefulWidget {
  const WorkspaceApp({required this.child, this.supabase, super.key});
  final Widget child;
  final SupabaseService? supabase;
  @override
  State<WorkspaceApp> createState() => _WorkspaceAppState();
}

class _WorkspaceAppState extends State<WorkspaceApp> {
  late final _supabase = widget.supabase ?? SupabaseService();
  late final _service = AccountWorkspaceService(_supabase);
  ProviderContainer? _container;
  StreamSubscription<dynamic>? _authSubscription;
  String? _sessionId;
  bool _switching = true, _entry = false;
  Object? _error;
  Future<void> _transitions = Future.value();
  Timer? _guestRetry;

  @override
  void initState() {
    super.initState();
    if (_supabase.isInitialized) {
      _authSubscription = _supabase.authStateChanges.listen((event) {
        final user = event.session?.user;
        if (user != null &&
            !user.isAnonymous &&
            HiveService.pendingGuestSource ==
                HiveService.accountWorkspaceId(user.id)) {
          unawaited(HiveService.clearGuestSource().catchError((Object _) {}));
        }
        if (_sessionId != event.session?.user.id || _container == null) {
          _enqueue();
        }
      }, onError: (Object _) {});
    }
    _enqueue();
    _guestRetry = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _provisionGuest(),
    );
  }

  void _enqueue() {
    _transitions = _transitions
        .catchError((Object _) {})
        .then((_) => _switch());
  }

  Future<void> _switch() async {
    if (!mounted) return;
    final nextId = _supabase.currentUserId;
    if (_container != null && _sessionId == nextId && _error == null) return;
    setState(() {
      _switching = true;
      _error = null;
    });
    try {
      final previous = _container;
      if (previous != null) {
        await previous
            .read(activeSessionProvider.notifier)
            .flushPendingChanges();
        await previous.read(nativeRestServiceProvider).cancel();
        await previous.read(workoutNotificationServiceProvider).cancelAll();
        // Wait until the old widget tree has unmounted before disposing refs.
        await WidgetsBinding.instance.endOfFrame;
        previous.dispose();
        _container = null;
      }
      final hive = await _service.selectSession();
      if (!mounted) return;
      _sessionId = _supabase.currentUserId;
      _container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWith(
            (ref) => HiveService(workspaceId: hive.workspaceId),
          ),
        ],
      );
      _container!.read(appBootstrappedProvider.notifier).markReady();
      setState(() {
        _entry = _service.needsEntry(hive);
        _switching = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _switching = false;
        });
      }
    }
  }

  Future<void> _provisionGuest() async {
    if (!mounted ||
        _switching ||
        _entry ||
        _container == null ||
        !_supabase.isInitialized ||
        _supabase.currentUserId != null) {
      return;
    }
    final container = _container!;
    final router = container.read(routerProvider);
    if (router.canPop() ||
        router.routeInformationProvider.value.uri.path !=
            AppConstants.routeDashboard) {
      return;
    }
    if (container.read(activeSessionProvider).isActive ||
        !container.read(onboardingCompleteProvider)) {
      return;
    }
    try {
      await HiveService.stageGuestSource(HiveService.activeWorkspaceId);
      await AuthService(_supabase).signInAnonymously();
    } catch (_) {
      /* Guest use remains local and immediate while offline. */
    }
  }

  @override
  void dispose() {
    _guestRetry?.cancel();
    unawaited(_authSubscription?.cancel());
    _container?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_switching || _error != null || _container == null) {
      return MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Center(
            child: _error == null
                ? const CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Could not open this account. Your local data is retained.',
                        ),
                        TextButton(
                          onPressed: _enqueue,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      );
    }
    return UncontrolledProviderScope(
      container: _container!,
      child: _entry
          ? _AccountEntry(
              service: _service,
              onReady: () {
                // The entry screen imported data before app providers were mounted.
                setState(() => _entry = false);
              },
            )
          : widget.child,
    );
  }
}

class _AccountEntry extends ConsumerStatefulWidget {
  const _AccountEntry({required this.service, required this.onReady});
  final AccountWorkspaceService service;
  final VoidCallback onReady;
  @override
  ConsumerState<_AccountEntry> createState() => _AccountEntryState();
}

class _AccountEntryState extends ConsumerState<_AccountEntry> {
  BackupPreview? _preview;
  bool _busy = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await widget.service.prepare(
        ref.read(hiveServiceProvider),
      );
      if (!mounted) return;
      if (preview == null) {
        widget.onReady();
        return;
      }
      setState(() {
        _preview = preview;
        _busy = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error =
              'Cloud restore could not finish. Retry when connected. Your original data is retained.';
        });
      }
    }
  }

  Future<void> _finish(RestoreMode? mode) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.finish(
        ref.read(hiveServiceProvider),
        _preview!,
        mode,
      );
      if (mounted) widget.onReady();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Import did not finish. Reload the preview and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      appBar: AppBar(title: const Text('Your account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_busy) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 20),
                    const Text('Restoring your account…'),
                  ],
                  if (_error != null) ...[
                    Text(_error!),
                    TextButton(
                      onPressed: _busy ? null : _load,
                      child: const Text('Retry'),
                    ),
                  ],
                  if (_preview != null && !_busy) ...[
                    const Text(
                      'Add this device’s guest data?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your account has been restored. Review the guest records below before adding them. The original guest copy stays on this device. Active workout drafts stay in their original workspace.',
                    ),
                    const SizedBox(height: 16),
                    for (final change in _preview!.changes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(change),
                      ),
                    FilledButton(
                      onPressed: () => _finish(RestoreMode.keepExisting),
                      child: const Text(
                        'Add guest data · keep account versions',
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _finish(RestoreMode.useBackup),
                      child: const Text('Add guest data · use guest versions'),
                    ),
                    TextButton(
                      onPressed: () => _finish(null),
                      child: const Text('Keep guest data separate'),
                    ),
                  ],
                  if (!_busy)
                    TextButton(
                      onPressed: () async {
                        try {
                          await AuthService(SupabaseService()).signOut();
                        } catch (_) {
                          if (mounted) {
                            setState(
                              () => _error = 'Could not sign out. Try again.',
                            );
                          }
                        }
                      },
                      child: const Text('Sign out'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

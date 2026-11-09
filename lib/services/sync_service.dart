import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/workout_session/providers/exercise_favorites_provider.dart';
import 'cloud_sync_engine.dart';
import 'hive_service.dart';
import 'pedometer_service.dart';
import 'supabase_service.dart';
import 'avatar_service.dart';

enum SyncStatus {
  idle,
  syncing,
  synced,
  offline,
  error,
  local,
  pending,
  conflict,
}

class SyncState {
  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncedAt,
    this.errorMessage,
    this.pendingCount = 0,
    this.conflicts = const {},
  });
  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
  final int pendingCount;
  final Map<String, JsonMap> conflicts;
  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    String? errorMessage,
    int? pendingCount,
    Map<String, JsonMap>? conflicts,
  }) => SyncState(
    status: status ?? this.status,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    errorMessage: errorMessage,
    pendingCount: pendingCount ?? this.pendingCount,
    conflicts: conflicts ?? this.conflicts,
  );
}

class SupabaseCloudTransport extends CloudTransport {
  SupabaseCloudTransport(this.supabase, {this.avatars});
  final SupabaseService supabase;
  final AvatarService? avatars;
  @override
  String? get currentUserId => supabase.currentUserId;
  void _check(String owner) {
    if (owner != currentUserId) {
      throw StateError('Account changed. Sign in again.');
    }
  }

  @override
  Future<List<JsonMap>> pull(String owner, int afterSequence) async {
    _check(owner);
    final rows = await supabase.client
        .from('cloud_records')
        .select('collection,record_key,data,revision,sequence')
        .eq('user_id', owner)
        .gt('sequence', afterSequence)
        .order('sequence', ascending: true)
        .limit(250)
        .timeout(const Duration(seconds: 30));
    _check(owner);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<List<JsonMap>> push(String owner, List<JsonMap> changes) async {
    _check(owner);
    await avatars?.uploadReferences(changes);
    _check(owner);
    final result = await supabase.client
        .rpc(
          'apply_cloud_changes',
          params: {'expected_user_id': owner, 'changes': changes},
        )
        .timeout(const Duration(seconds: 30));
    _check(owner);
    return (result as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}

final cloudTransportProvider = Provider<CloudTransport>(
  (ref) => SupabaseCloudTransport(
    ref.read(supabaseServiceProvider),
    avatars: ref.watch(avatarServiceProvider),
  ),
);
final syncServiceProvider = NotifierProvider<SyncService, SyncState>(
  SyncService.new,
);

class SyncService extends Notifier<SyncState> {
  CloudSyncEngine? _engine;
  Timer? _debounce, _retry, _poll;
  Future<void>? _running;
  int _failures = 0;
  bool _disposed = false;
  @override
  SyncState build() {
    _disposed = false;
    final hive = ref.read(hiveServiceProvider);
    final transport = ref.read(cloudTransportProvider);
    if (hive.ownerUserId != null) {
      _engine = CloudSyncEngine(
        hive,
        transport,
        onRemoteApplied: () {
          if (_disposed) return;
          ref.invalidate(hiveServiceProvider);
          ref.invalidate(exerciseFavoritesProvider);
          ref.invalidate(pedometerServiceProvider);
        },
      );
    }
    final subscription = HiveService.dataChanges.listen((workspace) {
      if (_disposed ||
          workspace != hive.workspaceId ||
          _running != null ||
          _engine == null) {
        return;
      }
      _refresh();
      if (state.pendingCount > state.conflicts.length) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(seconds: 2), syncAll);
      }
    });
    ref.onDispose(() {
      _disposed = true;
      _debounce?.cancel();
      _retry?.cancel();
      _poll?.cancel();
      unawaited(subscription.cancel());
    });
    return SyncState(
      status: _engine == null ? SyncStatus.local : SyncStatus.idle,
    );
  }

  /// Started by the application lifecycle, not by simply rendering an icon.
  void start() {
    _poll ??= Timer.periodic(const Duration(minutes: 1), (_) => syncAll());
    unawaited(syncAll());
  }

  void _refresh({SyncStatus? status, String? error}) {
    if (_disposed || _engine == null) return;
    final summary = _engine!.summary;
    state = SyncState(
      status:
          status ??
          (summary.conflicts.isNotEmpty
              ? SyncStatus.conflict
              : summary.pending > 0
              ? SyncStatus.pending
              : summary.lastSyncedAt != null
              ? SyncStatus.synced
              : SyncStatus.idle),
      pendingCount: summary.pending,
      conflicts: summary.conflicts,
      lastSyncedAt: summary.lastSyncedAt,
      errorMessage: error,
    );
  }

  Future<void> syncAll() {
    if (_disposed) return Future.value();
    return _running ??= _sync().whenComplete(() => _running = null);
  }

  Future<void> _sync() async {
    final engine = _engine;
    if (engine == null) {
      state = const SyncState(status: SyncStatus.local);
      return;
    }
    _retry?.cancel();
    try {
      _refresh(status: SyncStatus.syncing);
      await engine.synchronize();
      if (_disposed) return;
      _failures = 0;
      _refresh();
      if (state.pendingCount > state.conflicts.length) {
        _retry = Timer(const Duration(seconds: 2), syncAll);
      }
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('[CloudSync] ${error.runtimeType}: $error');
        debugPrintStack(label: '[CloudSync]', stackTrace: stack, maxFrames: 8);
      }
      if (_disposed) return;
      final offline = error is SocketException || error is TimeoutException;
      try {
        _refresh(
          status: offline ? SyncStatus.offline : SyncStatus.error,
          error: offline
              ? 'Saved on this device. Cloud sync will retry when connected.'
              : 'Cloud sync could not finish. Your local changes are retained. Retry, or sign in again.',
        );
      } catch (_) {
        state = const SyncState(
          status: SyncStatus.error,
          errorMessage:
              'Local data could not be read. No cloud save is confirmed.',
        );
      }
      _failures = (_failures + 1).clamp(1, 6);
      _retry = Timer(Duration(seconds: 5 * (1 << (_failures - 1))), syncAll);
    }
  }

  Future<void> resolveConflict(
    String key, {
    required bool useLocal,
    int? reviewedRevision,
  }) async {
    await _running;
    if (_disposed || _engine == null) return;
    await _engine!.resolveConflict(
      key,
      useLocal: useLocal,
      reviewedRevision: reviewedRevision,
    );
    await syncAll();
  }
}

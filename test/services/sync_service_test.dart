import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/services/sync_service.dart';
import 'dart:io';
import 'package:leon/services/hive_service.dart';
import 'cloud_sync_engine_test.dart' show FakeCloud, owner, save;

class OfflineCloud extends FakeCloud {
  bool offline = false;
  @override
  Future<List<Map<String, dynamic>>> pull(
    String user,
    int afterSequence,
  ) async {
    if (offline) throw const SocketException('Offline test');
    return super.pull(user, afterSequence);
  }
}

void main() {
  test(
    'real Hive edits update pending state and offline retry preserves data',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'leon_sync_service_',
      );
      await HiveService.init(storagePath: directory.path);
      final hive = await HiveService.openWorkspace(
        HiveService.accountWorkspaceId(owner),
      );
      final cloud = OfflineCloud();
      final container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(hive),
          cloudTransportProvider.overrideWithValue(cloud),
        ],
      );
      try {
        final service = container.read(syncServiceProvider.notifier);
        await service.syncAll();
        expect(container.read(syncServiceProvider).status, SyncStatus.synced);
        await save(hive, 75);
        await Future<void>.delayed(Duration.zero);
        expect(container.read(syncServiceProvider).status, SyncStatus.pending);
        expect(container.read(syncServiceProvider).pendingCount, 1);
        cloud.offline = true;
        await service.syncAll();
        expect(container.read(syncServiceProvider).status, SyncStatus.offline);
        expect(container.read(syncServiceProvider).pendingCount, 1);
        cloud.offline = false;
        await service.syncAll();
        expect(container.read(syncServiceProvider).status, SyncStatus.synced);
        expect(container.read(syncServiceProvider).pendingCount, 0);
        expect(container.read(syncServiceProvider).errorMessage, isNull);
        expect(cloud.rows.length, 1);
      } finally {
        container.dispose();
        await HiveService.close();
        await directory.delete(recursive: true);
      }
    },
  );
  group('SyncService & SyncState Tests', () {
    test('Default state is idle with 0 pending items', () {
      const state = SyncState();
      expect(state.status, SyncStatus.idle);
      expect(state.pendingCount, 0);
      expect(state.lastSyncedAt, isNull);
      expect(state.errorMessage, isNull);
    });

    test('SyncState copyWith updates fields correctly', () {
      final now = DateTime.now();
      const initial = SyncState();
      final updated = initial.copyWith(
        status: SyncStatus.synced,
        lastSyncedAt: now,
        pendingCount: 0,
      );

      expect(updated.status, SyncStatus.synced);
      expect(updated.lastSyncedAt, now);
      expect(updated.pendingCount, 0);
    });

    test('Guest provider truthfully reports local storage', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final syncState = container.read(syncServiceProvider);
      expect(syncState.status, SyncStatus.local);

      final notifier = container.read(syncServiceProvider.notifier);
      expect(notifier, isA<SyncService>());
    });

    test(
      'syncAll safely handles offline/uninitialized state without throwing',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(syncServiceProvider.notifier);
        await expectLater(notifier.syncAll(), completes);

        final finalState = container.read(syncServiceProvider);
        expect(
          finalState.status == SyncStatus.local ||
              finalState.status == SyncStatus.offline ||
              finalState.status == SyncStatus.error ||
              finalState.status == SyncStatus.synced,
          isTrue,
        );
      },
    );
  });
}

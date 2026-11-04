import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/services/sync_service.dart';

void main() {
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

    test('ProviderContainer resolves SyncService and defaults to idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final syncState = container.read(syncServiceProvider);
      expect(syncState.status, SyncStatus.idle);

      final notifier = container.read(syncServiceProvider.notifier);
      expect(notifier, isA<SyncService>());
    });

    test('syncAll safely handles offline/uninitialized state without throwing', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(syncServiceProvider.notifier);
      await expectLater(notifier.syncAll(), completes);

      final finalState = container.read(syncServiceProvider);
      expect(
        finalState.status == SyncStatus.offline ||
            finalState.status == SyncStatus.error ||
            finalState.status == SyncStatus.synced,
        isTrue,
      );
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/services/hive_service.dart';

void main() {
  const firstId = '11111111-1111-4111-8111-111111111111';
  const secondId = '22222222-2222-4222-8222-222222222222';
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('leon_workspace_');
    await HiveService.init(storagePath: directory.path);
  });
  tearDown(() async {
    await HiveService.close();
    await directory.delete(recursive: true);
  });

  test(
    'upgrade retains original guest boxes while each owner is isolated',
    () async {
      const guest = HiveService();
      await guest.put('workouts', 'shared-id', {'name': 'Guest workout'});
      await guest.putSettingChecked('active_session_data', {'draft': 'guest'});
      final first = await HiveService.openWorkspace(
        HiveService.accountWorkspaceId(firstId),
      );
      expect(first.readAll('workouts', (json) => json), isEmpty);
      expect(first.getSetting<Map>('active_session_data'), isNull);
      await first.put('workouts', 'shared-id', {'name': 'First account'});
      await first.putSettingChecked('active_session_data', {'draft': 'first'});
      final second = await HiveService.openWorkspace(
        HiveService.accountWorkspaceId(secondId),
      );
      await second.put('workouts', 'shared-id', {'name': 'Second account'});
      expect(
        guest.read('workouts', 'shared-id', (json) => json)!['name'],
        'Guest workout',
      );
      expect(
        first.read('workouts', 'shared-id', (json) => json)!['name'],
        'First account',
      );
      expect(
        second.read('workouts', 'shared-id', (json) => json)!['name'],
        'Second account',
      );
      expect(guest.getSetting<Map>('active_session_data')!['draft'], 'guest');
      expect(first.getSetting<Map>('active_session_data')!['draft'], 'first');
      expect(second.getSetting<Map>('active_session_data'), isNull);
    },
  );

  test(
    'selection survives restart and provider resolves only selected owner',
    () async {
      final account = HiveService.accountWorkspaceId(firstId);
      final store = await HiveService.openWorkspace(account);
      await store.put('user', 'local', {'id': firstId});
      await HiveService.selectWorkspace(account);
      await HiveService.close();
      await HiveService.init(storagePath: directory.path);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final selected = container.read(hiveServiceProvider);
      expect(selected.ownerUserId, firstId);
      expect(selected.read('user', 'local', (json) => json)!['id'], firstId);
      expect(HiveService.activeWorkspaceId, account);
    },
  );

  test('writes using an old service cannot cross a workspace switch', () async {
    final first = await HiveService.openWorkspace(
      HiveService.accountWorkspaceId(firstId),
    );
    final second = await HiveService.openWorkspace(
      HiveService.accountWorkspaceId(secondId),
    );
    await HiveService.selectWorkspace(first.workspaceId);
    final pending = first.put('workouts', 'pending', {'owner': firstId});
    await HiveService.selectWorkspace(second.workspaceId);
    await pending;
    await first.putSettingChecked('late-save', firstId);
    expect(
      first.read('workouts', 'pending', (json) => json)!['owner'],
      firstId,
    );
    expect(second.read('workouts', 'pending', (json) => json), isNull);
    expect(second.getSetting<String>('late-save'), isNull);
  });

  test('failed restore rolls back only its own workspace', () async {
    final first = await HiveService.openWorkspace(
      HiveService.accountWorkspaceId(firstId),
    );
    final second = await HiveService.openWorkspace(
      HiveService.accountWorkspaceId(secondId),
    );
    await first.put('workouts', 'one', {'value': 1});
    await second.put('workouts', 'two', {'value': 2});
    final original = first.snapshot();
    final replacement =
        jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
    (replacement['documents'] as Map)['workouts'] = {
      'three': {'value': 3},
    };
    await expectLater(
      first.restoreSnapshot(
        replacement,
        expectedSnapshot: jsonEncode(original),
        beforeBoxWrite: (box) async {
          if (box == AppConstants.hiveBoxUser) {
            throw StateError('Simulated disk failure');
          }
        },
      ),
      throwsStateError,
    );
    expect(first.snapshot(), original);
    expect(second.read('workouts', 'two', (json) => json)!['value'], 2);
  });

  test(
    'unfinished restore recovers in selected workspace after restart',
    () async {
      final account = HiveService.accountWorkspaceId(firstId);
      final first = await HiveService.openWorkspace(account);
      await first.put('workouts', 'saved', {'value': 1});
      final before = first.snapshot();
      await first.putSettingChecked('_restore_journal', jsonEncode(before));
      await first.delete('workouts', 'saved');
      // Persist the selection without invoking normal recovery on the open boxes.
      await Hive.box<String>(
        'leon_workspaces_v1',
      ).put('active_workspace', account);
      await HiveService.close();
      await HiveService.init(storagePath: directory.path);
      expect(first.read('workouts', 'saved', (json) => json)!['value'], 1);
      expect(first.getSetting<String>('_restore_journal'), isNull);
    },
  );

  test(
    'failed reconciliation restores pre-transform data and metadata',
    () async {
      const hive = HiveService();
      await hive.put('workouts', 'original', {'name': 'Original'});
      await hive.putSettingChecked('cloud_sync_state_v1', {'cursor': 1});
      final before = hive.snapshot();
      await expectLater(
        hive.restoreSnapshot(
          const {},
          expectedSnapshot: jsonEncode(before),
          reconcile: (latest) {
            (latest['documents'] as Map)['workouts'] = {
              'download': {'name': 'Downloaded'},
            };
            (latest['settings'] as Map)['cloud_sync_state_v1'] = {'cursor': 2};
            return latest;
          },
          beforeBoxWrite: (box) async {
            if (box == 'user') throw StateError('Disk write failed');
          },
        ),
        throwsStateError,
      );
      expect(hive.snapshot(), before);
      await HiveService.close();
      await HiveService.init(storagePath: directory.path);
      expect(hive.snapshot(), before);
    },
  );

  test('failed selection leaves the active owner unchanged', () async {
    final previous = HiveService.activeWorkspaceId;
    await Hive.box<String>('leon_workspaces_v1').close();
    await expectLater(
      HiveService.selectWorkspace(HiveService.accountWorkspaceId(firstId)),
      throwsA(isA<HiveError>()),
    );
    expect(HiveService.activeWorkspaceId, previous);
  });

  test('workspace names cannot escape the database directory', () async {
    await expectLater(
      HiveService.openWorkspace('../another-account'),
      throwsArgumentError,
    );
    expect(
      () => HiveService.accountWorkspaceId('../owner'),
      throwsArgumentError,
    );
  });
}

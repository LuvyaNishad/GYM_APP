import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:leon/services/account_workspace_service.dart';
import 'package:leon/services/backup_service.dart';
import 'package:leon/services/cloud_sync_engine.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/services/supabase_service.dart';
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/core/router/app_router.dart';
import 'package:leon/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cloud_sync_engine_test.dart' show FakeCloud, owner, save, workout;

class SessionStub extends SupabaseService {
  User? user;
  @override
  User? get currentUser => user;
  @override
  String? get currentUserId => user?.id;
}

User identity(String id, {bool anonymous = false}) => User(
  id: id,
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-11-05T00:00:00Z',
  isAnonymous: anonymous,
);
Map<String, dynamic> record(double load) =>
    jsonDecode(jsonEncode(workout(load))) as Map<String, dynamic>;

void main() {
  late Directory directory;
  late SessionStub session;
  late FakeCloud cloud;
  late AccountWorkspaceService service;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('leon_account_');
    await HiveService.init(storagePath: directory.path);
    session = SessionStub();
    cloud = FakeCloud();
    service = AccountWorkspaceService(session, transport: cloud);
  });
  tearDown(() async {
    await HiveService.close();
    await directory.delete(recursive: true);
  });
  test(
    'fresh early sign-in restores the saved profile and opens Home without setup or empty import',
    () async {
      final original = await HiveService.openWorkspace(
        HiveService.accountWorkspaceId(owner),
      );
      await original.put(
        AppConstants.hiveBoxUser,
        AppConstants.hiveKeyLocalProfile,
        const UserModel(
          id: owner,
          email: 'lifter@example.invalid',
          displayName: 'Returning lifter',
          onboardingComplete: true,
          preferredSplit: 'split_ppl',
          trainingDaysPerWeek: 5,
        ).toJson(),
      );
      await save(original, 80);
      await CloudSyncEngine(original, cloud).synchronize();
      await HiveService.close();
      await HiveService.init(storagePath: '${directory.path}/fresh-return');
      await HiveService.stageGuestSource('guest');
      session.user = identity(owner);
      final restored = await service.selectSession();
      expect(await service.prepare(restored), isNull);
      expect(service.needsEntry(restored), isFalse);
      expect(restored.readAll('workouts', (j) => j), [record(80)]);
      final providers = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(restored)],
      );
      expect(
        providers.read(routerProvider).routeInformationProvider.value.uri.path,
        AppConstants.routeDashboard,
      );
      providers.dispose();
    },
  );

  test(
    'recovery marker survives reopen outside portable workout data',
    () async {
      await HiveService.setPendingRecoveryOwner(owner);
      final snapshot = const HiveService().snapshot();
      expect(
        (snapshot['settings'] as Map).containsKey('password_recovery_owner'),
        isFalse,
      );
      await HiveService.close();
      await HiveService.init(storagePath: directory.path);
      expect(HiveService.pendingRecoveryOwner, owner);
      await HiveService.setPendingRecoveryOwner(null);
      expect(HiveService.pendingRecoveryOwner, isNull);
    },
  );
  test(
    'guest data is retained and requires explicit import after account restore',
    () async {
      const guest = HiveService();
      await save(guest, 65);
      await guest.putSettingChecked('active_session_data', {'draft': 'guest'});
      await HiveService.stageGuestSource('guest');
      session.user = identity(owner);
      final account = await service.selectSession();
      expect(account.readAll('workouts', (j) => j), isEmpty);
      expect(account.getSetting('active_session_data'), isNull);
      final preview = await service.prepare(account);
      expect(preview, isNotNull);
      expect(account.readAll('workouts', (j) => j), isEmpty);
      expect(cloud.rows, isEmpty);
      await service.finish(account, preview!, RestoreMode.keepExisting);
      expect(account.readAll('workouts', (j) => j), [record(65)]);
      expect(guest.readAll('workouts', (j) => j), [record(65)]);
      expect(guest.getSetting('active_session_data'), {'draft': 'guest'});
      await CloudSyncEngine(account, cloud).synchronize();
      expect(cloud.rows.length, 1);
      expect(service.needsEntry(account), isFalse);
    },
  );
  test(
    'restore account first then keep reviewed account version during guest merge',
    () async {
      const guest = HiveService();
      await save(guest, 65);
      final otherDevice = await HiveService.openWorkspace(
        HiveService.accountWorkspaceId(owner),
      );
      await save(otherDevice, 80);
      await CloudSyncEngine(otherDevice, cloud).synchronize();
      // Simulate a fresh account cache using a separate local database directory.
      await HiveService.close();
      await HiveService.init(storagePath: '${directory.path}/fresh');
      await save(guest, 65);
      await HiveService.stageGuestSource('guest');
      session.user = identity(owner);
      final account = await service.selectSession();
      final preview = await service.prepare(account);
      expect(account.readAll('workouts', (j) => j), [record(80)]);
      await service.finish(account, preview!, RestoreMode.keepExisting);
      expect(account.readAll('workouts', (j) => j), [record(80)]);
      expect(guest.readAll('workouts', (j) => j), [record(65)]);
    },
  );
  test(
    'sign-out and another sign-in cannot expose the previous local account',
    () async {
      session.user = identity(owner);
      final account = await service.selectSession();
      await save(account, 90);
      session.user = null;
      final guest = await service.selectSession();
      expect(guest.ownerUserId, isNull);
      expect(guest.readAll('workouts', (j) => j), isEmpty);
      session.user = identity('22222222-2222-4222-8222-222222222222');
      final second = await service.selectSession();
      expect(second.readAll('workouts', (j) => j), isEmpty);
      expect(account.readAll('workouts', (j) => j), [record(90)]);
    },
  );
  test(
    'pending import survives restart and can be declined without deleting guest data',
    () async {
      const guest = HiveService();
      await save(guest, 55);
      await HiveService.stageGuestSource('guest');
      session.user = identity(owner);
      await service.selectSession();
      await HiveService.close();
      await HiveService.init(storagePath: directory.path);
      final account = await service.selectSession();
      final preview = await service.prepare(account);
      await service.finish(account, preview!, null);
      expect(account.readAll('workouts', (j) => j), isEmpty);
      expect(guest.readAll('workouts', (j) => j), [record(55)]);
    },
  );
}

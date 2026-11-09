import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/features/profile/models/avatar_reference.dart';
import 'package:leon/models/user_model.dart';
import 'package:leon/services/avatar_service.dart';
import 'package:leon/services/backup_service.dart';
import 'package:leon/services/cloud_sync_engine.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/services/profile_storage.dart';

const owner = '11111111-1111-4111-8111-111111111111';
const photoId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
Uint8List photoBytes() =>
    Uint8List.fromList(img.encodeJpg(img.Image(width: 64, height: 64)));

class MediaCloud implements AvatarTransport {
  @override
  String? currentUserId = owner;
  bool fail = false;
  int uploads = 0, downloads = 0;
  final images = <String, Uint8List>{};
  Completer<void>? gate;
  @override
  Future<void> upload(String user, String id, Uint8List bytes) async {
    uploads++;
    await gate?.future;
    if (fail) throw const SocketException('Offline');
    images['$user/$id'] = bytes;
  }

  @override
  Future<Uint8List> download(String user, String id) async {
    downloads++;
    return images['$user/$id']!;
  }
}

class FailingHive extends HiveService {
  @override
  Future<void> restoreSnapshot(
    Map<String, dynamic> replacement, {
    required String expectedSnapshot,
    String Function(Map<String, dynamic>)? fingerprint,
    Map<String, dynamic> Function(Map<String, dynamic>)? reconcile,
    Future<void> Function(String)? beforeBoxWrite,
  }) => super.restoreSnapshot(
    replacement,
    expectedSnapshot: expectedSnapshot,
    fingerprint: fingerprint,
    reconcile: reconcile,
    beforeBoxWrite: (box) async {
      if (box == 'user') throw StateError('Disk failed');
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('aeon_avatar_');
    await HiveService.init(storagePath: directory.path);
    await const HiveService().put(
      'user',
      AppConstants.hiveKeyLocalProfile,
      UserModel(
        id: 'guest_user',
        email: '',
        displayName: 'Alex',
        createdAt: DateTime(2026),
        avatarUrl: AvatarReference.preset('sage'),
      ).toJson(),
    );
  });
  tearDown(() async {
    await HiveService.close();
    await directory.delete(recursive: true);
  });

  test(
    'avatar save preserves migrated setup, preferences and profile after restart',
    () async {
      const hive = HiveService();
      final legacy = hive.read(
        'user',
        AppConstants.hiveKeyLocalProfile,
        (json) => json,
      )!;
      legacy.remove('onboarding_complete');
      legacy.remove('available_plates');
      legacy.remove('barbell_tare_kg');
      legacy.remove('primary_goal');
      legacy.remove('schema_version');
      legacy.remove('height_cm');
      legacy.remove('current_weight');
      await hive.put('user', AppConstants.hiveKeyLocalProfile, legacy);
      await hive.put('user', 'account_profile_data', {
        'height_cm': 180.0,
        'current_weight_kg': 80.0,
      });
      await hive.putSettingChecked(
        AppConstants.settingOnboardingComplete,
        true,
      );
      await hive.putSettingChecked(AppConstants.settingPrimaryGoal, 'STRENGTH');
      await hive.putSettingChecked('plate_preferences_v1', {
        'bar': 15.0,
        'plates': [20.0, 10.0, 5.0],
      });
      final before = readLocalProfile(hive)!;
      expect(before.onboardingComplete, isTrue);
      expect(before.heightCm, 180);
      await AvatarService(hive).save(AvatarReference.preset('graphite'));
      await HiveService.close();
      await HiveService.init(storagePath: directory.path);
      final after = readLocalProfile(hive)!;
      expect(
        after.copyWith(
          avatarUrl: before.avatarUrl,
          lastActiveAt: before.lastActiveAt,
        ),
        before,
      );
      expect(
        hive
            .read('user', AppConstants.hiveKeyLocalProfile, UserModel.fromJson)!
            .onboardingComplete,
        isTrue,
      );
    },
  );

  test(
    'saved completion recovers a legacy profile rewritten by the previous avatar save',
    () async {
      const hive = HiveService();
      // The earlier saver materialized false while the completed setting remained true.
      await hive.putSettingChecked(
        AppConstants.settingOnboardingComplete,
        true,
      );
      expect(readLocalProfile(hive)!.onboardingComplete, isTrue);
      await HiveService.close();
      await HiveService.init(storagePath: directory.path);
      expect(readLocalProfile(hive)!.onboardingComplete, isTrue);
    },
  );

  test(
    'avatar save retains an older account-only profile and stays owner-scoped',
    () async {
      const hive = HiveService();
      await hive.delete('user', AppConstants.hiveKeyLocalProfile);
      await hive.put('user', 'account_profile_data', {
        'id': 'guest_user',
        'display_name': 'Morgan',
        'email': '',
        'current_weight_kg': 75.0,
        'member_since': DateTime(2025).toIso8601String(),
      });
      await hive.putSettingChecked(
        AppConstants.settingOnboardingComplete,
        true,
      );
      final before = readLocalProfile(hive)!;
      await AvatarService(hive).save(AvatarReference.preset('olive'));
      final after = readLocalProfile(hive)!;
      expect(
        after.copyWith(
          avatarUrl: before.avatarUrl,
          lastActiveAt: before.lastActiveAt,
        ),
        before,
      );
      final account = await HiveService.openWorkspace(
        HiveService.accountWorkspaceId(owner),
      );
      await AvatarService(account).save(AvatarReference.preset('sage'));
      expect(readLocalProfile(account)!.onboardingComplete, isFalse);
      expect(readLocalProfile(account)!.displayName, isEmpty);
    },
  );

  test(
    'photo persists across restart and removal preserves identity',
    () async {
      final bytes = await normalizeAvatar(photoBytes());
      await AvatarService(
        const HiveService(),
      ).save(AvatarReference.photo(photoId), bytes: bytes);
      await HiveService.close();
      await HiveService.init(storagePath: directory.path);
      final service = AvatarService(const HiveService());
      expect(service.cached(photoId), bytes);
      final stored = service.hive.read(
        'user',
        AppConstants.hiveKeyLocalProfile,
        UserModel.fromJson,
      )!;
      expect(stored.avatarUrl, AvatarReference.photo(photoId));
      expect(stored.displayName, 'Alex');
      await service.save(null);
      expect(
        service.hive
            .read('user', AppConstants.hiveKeyLocalProfile, UserModel.fromJson)!
            .avatarUrl,
        isNull,
      );
      expect(
        service.hive.read(
          'user',
          'account_profile_data',
          (j) => j,
        )!['avatar_url'],
        isNull,
      );
    },
  );

  test(
    'journalled failure preserves old picture and does not stage orphan bytes',
    () async {
      final hive = FailingHive();
      final before = jsonEncode(hive.snapshot());
      await expectLater(
        AvatarService(
          hive,
        ).save(AvatarReference.photo(photoId), bytes: photoBytes()),
        throwsStateError,
      );
      expect(jsonEncode(hive.snapshot()), before);
    },
  );

  test(
    'photos import and back up offline without entering cloud JSON',
    () async {
      const guest = HiveService();
      await AvatarService(
        guest,
      ).save(AvatarReference.photo(photoId), bytes: photoBytes());
      final backup = await BackupService(guest).export();
      final account = await HiveService.openWorkspace(
        HiveService.accountWorkspaceId(owner),
      );
      final preview = await BackupService(account).preview(backup);
      await BackupService(account).restore(preview, RestoreMode.useBackup);
      expect(AvatarService(account).cached(photoId), photoBytes());
      expect(
        account
            .read('user', AppConstants.hiveKeyLocalProfile, UserModel.fromJson)!
            .avatarUrl,
        AvatarReference.photo(photoId),
      );
      final records = CloudSyncEngine.records(account.snapshot());
      expect(
        records.containsKey(
          CloudSyncEngine.key('settings', AvatarReference.imagesKey),
        ),
        isFalse,
      );
      expect(
        records.values.any(
          (r) => jsonEncode(r).contains(base64Encode(photoBytes())),
        ),
        isFalse,
      );
      final other = await HiveService.openWorkspace(
        HiveService.accountWorkspaceId('22222222-2222-4222-8222-222222222222'),
      );
      expect(AvatarService(other).cached(photoId), isNull);
      final broken = jsonDecode(utf8.decode(backup)) as Map;
      broken['settings'][AvatarReference.imagesKey][photoId] = 'not an image';
      await expectLater(
        BackupService(
          account,
        ).preview(Uint8List.fromList(utf8.encode(jsonEncode(broken)))),
        throwsFormatException,
      );
    },
  );

  test('failed uploads retry and fresh devices cache private bytes', () async {
    final hive = await HiveService.openWorkspace(
      HiveService.accountWorkspaceId(owner),
    );
    final cloud = MediaCloud()..fail = true;
    final service = AvatarService(hive, transport: cloud);
    await service.save(AvatarReference.photo(photoId), bytes: photoBytes());
    final changes = [
      {
        'collection': 'user',
        'data': {'avatar_url': AvatarReference.photo(photoId)},
      },
    ];
    await expectLater(
      service.uploadReferences(changes),
      throwsA(isA<SocketException>()),
    );
    expect(hive.getSetting<Map>(AvatarService.receiptsKey), isNull);
    cloud.fail = false;
    await service.uploadReferences(changes);
    await service.uploadReferences(changes);
    expect(cloud.uploads, 2);
    await hive.deleteSettingChecked(AvatarReference.imagesKey);
    await BackupService(hive, avatars: service).export();
    expect(service.cached(photoId), photoBytes());
    expect(cloud.downloads, 1);
  });

  test('account switch while uploading never records a receipt', () async {
    final hive = await HiveService.openWorkspace(
      HiveService.accountWorkspaceId(owner),
    );
    final cloud = MediaCloud()..gate = Completer<void>();
    final service = AvatarService(hive, transport: cloud);
    await service.save(AvatarReference.photo(photoId), bytes: photoBytes());
    final pending = service.uploadReferences([
      {
        'collection': 'user',
        'data': {'avatar_url': AvatarReference.photo(photoId)},
      },
    ]);
    cloud.currentUserId = 'another-owner';
    cloud.gate!.complete();
    await expectLater(pending, throwsStateError);
    expect(hive.getSetting<Map>(AvatarService.receiptsKey), isNull);
  });
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../features/profile/models/account_profile_model.dart';
import '../features/profile/models/avatar_reference.dart';
import '../models/user_model.dart';
import 'hive_service.dart';
import 'profile_storage.dart';
import 'supabase_service.dart';

const avatarMaxBytes = 512 * 1024;

void validateAvatarBytes(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > avatarMaxBytes) {
    throw const FormatException('Picture must be smaller than 512 KB.');
  }
  final info = img.JpegDecoder(maxPixels: 512 * 512).startDecode(bytes);
  if (info == null ||
      info.width != info.height ||
      info.width < 1 ||
      info.width > 512) {
    throw const FormatException(
      'Picture must be a square JPEG, up to 512 pixels.',
    );
  }
}

Uint8List _normalize(Uint8List bytes) {
  validateAvatarBytes(bytes);
  final decoded = img.JpegDecoder(maxPixels: 512 * 512).decode(bytes);
  if (decoded == null) {
    throw const FormatException('This picture could not be read.');
  }
  // Re-encode without source EXIF/location data.
  final clean = img.Image(
    width: decoded.width,
    height: decoded.height,
    numChannels: 3,
  );
  img.compositeImage(clean, decoded);
  return Uint8List.fromList(img.encodeJpg(clean, quality: 88));
}

Future<Uint8List> normalizeAvatar(Uint8List bytes) =>
    compute(_normalize, bytes);

void validateAvatarCache(Object? value) {
  if (value is! Map || value.length > 64) {
    throw const FormatException('Invalid profile pictures.');
  }
  for (final entry in value.entries) {
    if (entry.key is! String ||
        !AvatarReference.uuid.hasMatch(entry.key as String) ||
        entry.value is! String) {
      throw const FormatException('Invalid profile picture entry.');
    }
    final raw = entry.value as String;
    if (raw.length > (avatarMaxBytes * 4 / 3).ceil() + 4) {
      throw const FormatException('Profile picture is too large.');
    }
    validateAvatarBytes(base64Decode(raw));
  }
}

abstract class AvatarTransport {
  String? get currentUserId;
  Future<void> upload(String owner, String id, Uint8List bytes);
  Future<Uint8List> download(String owner, String id);
}

class SupabaseAvatarTransport implements AvatarTransport {
  SupabaseAvatarTransport(this.supabase);
  final SupabaseService supabase;
  @override
  String? get currentUserId => supabase.currentUserId;
  void _check(String owner) {
    if (currentUserId != owner) throw StateError('Account changed.');
  }

  @override
  Future<void> upload(String owner, String id, Uint8List bytes) async {
    _check(owner);
    await supabase.client.storage
        .from('avatars')
        .uploadBinary(
          '$owner/$id.jpg',
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        )
        .timeout(const Duration(seconds: 30));
    _check(owner);
  }

  @override
  Future<Uint8List> download(String owner, String id) async {
    _check(owner);
    final bytes = await supabase.client.storage
        .from('avatars')
        .download('$owner/$id.jpg')
        .timeout(const Duration(seconds: 30));
    _check(owner);
    return bytes;
  }
}

/// Every operation stays bound to the workspace in which it began.
class AvatarService {
  AvatarService(this.hive, {this.transport});
  final HiveService hive;
  final AvatarTransport? transport;
  static const receiptsKey = 'avatar_uploaded_v1';
  Map<String, dynamic> get _cache => Map<String, dynamic>.from(
    hive.getSetting<Map>(AvatarReference.imagesKey) ?? {},
  );

  Uint8List? cached(String id) {
    final raw = _cache[id];
    if (raw is! String) return null;
    final bytes = base64Decode(raw);
    validateAvatarBytes(bytes);
    return bytes;
  }

  Future<void> save(String? reference, {Uint8List? bytes}) async {
    final id = AvatarReference.photoId(reference);
    if (bytes != null) validateAvatarBytes(bytes);
    if (reference != null &&
        id == null &&
        AvatarReference.presetId(reference) == null) {
      throw const FormatException('Choose a profile picture.');
    }
    await hive.changeSnapshot((snapshot) {
      final settings = snapshot['settings'] as Map;
      final cache = Map<String, dynamic>.from(
        settings[AvatarReference.imagesKey] as Map? ?? {},
      );
      if (id != null) {
        if (bytes != null) cache[id] = base64Encode(bytes);
        if (!cache.containsKey(id)) {
          throw StateError('Choose the picture again.');
        }
        // Retain recent choices, plus every profile/pending/conflict reference.
        // Never prune an image a durable cloud retry still needs.
        final protected = <String>{id};
        void references(Object? value) {
          if (value is Map) {
            for (final item in value.values) {
              references(item);
            }
          } else if (value is List) {
            for (final item in value) {
              references(item);
            }
          } else if (value is String) {
            final photo = AvatarReference.photoId(value);
            if (photo != null) protected.add(photo);
          }
        }

        references(snapshot['documents']);
        references(settings['cloud_sync_state_v1']);
        for (final key in cache.keys.toList()) {
          if (cache.length <= 16) break;
          if (!protected.contains(key)) cache.remove(key);
        }
        validateAvatarCache(cache);
        settings[AvatarReference.imagesKey] = cache;
      }
      final users = (snapshot['documents'] as Map)['user'] as Map;
      final user =
          (readProfileSnapshot(snapshot) ??
                  UserModel(
                    id: hive.ownerUserId ?? 'local',
                    email: '',
                    displayName: '',
                    createdAt: DateTime.now(),
                  ))
              .copyWith(avatarUrl: reference, lastActiveAt: DateTime.now());
      users[AppConstants.hiveKeyLocalProfile] = user.toJson();
      users['account_profile_data'] = AccountProfile.fromUser(user).toJson();
      return snapshot;
    });
  }

  Future<Uint8List?> load(String id) async {
    final local = cached(id);
    if (local != null) return local;
    final owner = hive.ownerUserId;
    if (owner == null || transport == null) return null;
    final bytes = await transport!.download(owner, id);
    validateAvatarBytes(bytes);
    if (transport!.currentUserId != owner) throw StateError('Account changed.');
    await hive.changeSnapshot((snapshot) {
      final settings = snapshot['settings'] as Map;
      final cache = Map<String, dynamic>.from(
        settings[AvatarReference.imagesKey] as Map? ?? {},
      );
      // Leave the display usable even when the retained picture cache is full.
      if (cache.length < 64 || cache.containsKey(id)) {
        cache[id] = base64Encode(bytes);
        settings[AvatarReference.imagesKey] = cache;
      }
      return snapshot;
    });
    return bytes;
  }

  /// Called for the actual durable outgoing batch, including retries/conflicts.
  Future<void> uploadReferences(List<Map<String, dynamic>> changes) async {
    final owner = hive.ownerUserId;
    if (owner == null || transport == null) return;
    final ids = <String>{};
    for (final change in changes) {
      if (change['collection'] != 'user' || change['data'] is! Map) continue;
      final data = change['data'] as Map;
      final id = AvatarReference.photoId(
        (data['avatar_url'] ?? data['avatarUrl']) as String?,
      );
      if (id != null) ids.add(id);
    }
    for (final id in ids) {
      if (transport!.currentUserId != owner) {
        throw StateError('Account changed.');
      }
      final receipts = Map<String, dynamic>.from(
        hive.getSetting<Map>(receiptsKey) ?? {},
      );
      if (receipts[id] == true) continue;
      final bytes = cached(id);
      if (bytes == null) {
        // A restored cloud reference may already exist remotely.
        validateAvatarBytes(await transport!.download(owner, id));
      } else {
        await transport!.upload(owner, id, bytes);
      }
      if (transport!.currentUserId != owner) {
        throw StateError('Account changed.');
      }
      receipts[id] = true;
      await hive.putSettingChecked(receiptsKey, receipts);
    }
  }
}

final avatarServiceProvider = Provider(
  (ref) => AvatarService(
    ref.watch(hiveServiceProvider),
    transport: SupabaseAvatarTransport(ref.read(supabaseServiceProvider)),
  ),
);
final avatarBytesProvider = FutureProvider.autoDispose
    .family<Uint8List?, String>(
      (ref, id) => ref.watch(avatarServiceProvider).load(id),
    );

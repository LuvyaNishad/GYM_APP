import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/avatar_service.dart';
import '../../../services/cloud_sync_engine.dart';
import '../../../services/hive_service.dart';
import '../../../state/app_providers.dart';
import '../models/avatar_reference.dart';
import 'profile_provider.dart';

enum AvatarSource { gallery, camera, files }

abstract class AvatarPhotoPicker {
  Future<Uint8List?> pick(AvatarSource source);
}

class NativeAvatarPhotoPicker implements AvatarPhotoPicker {
  @override
  Future<Uint8List?> pick(AvatarSource source) async {
    String? path;
    if (source == AvatarSource.files) {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'webp',
          'heic',
          'heif',
          'gif',
          'bmp',
          'avif',
        ],
      );
      path = result?.path;
    } else {
      final selected = await ImagePicker().pickImage(
        source: source == AvatarSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
        requestFullMetadata: false,
      );
      path = selected?.path;
    }
    if (path == null) return null;
    return cropPath(path);
  }

  Future<Uint8List?> cropPath(String path) async {
    if (await File(path).length() > 20 * 1024 * 1024) {
      throw const FormatException('Choose a picture smaller than 20 MB.');
    }
    final cropped = await ImageCropper().cropImage(
      sourcePath: path,
      maxWidth: 512,
      maxHeight: 512,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 88,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop picture',
          toolbarColor: AppColors.onyx,
          toolbarWidgetColor: AppColors.textPrimary,
          backgroundColor: AppColors.onyx,
          // uCrop's scale wheel is white even with a dark preview background.
          activeControlsWidgetColor: const Color(0xFF63795D),
          cropFrameColor: AppColors.primary,
          dimmedLayerColor: const Color(0xB30F131B),
          statusBarLight: false,
          navBarLight: false,
          cropStyle: CropStyle.circle,
          lockAspectRatio: true,
          showCropGrid: false,
          hideBottomControls: false,
          aspectRatioPresets: [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: 'Crop picture',
          doneButtonTitle: 'Use picture',
          cancelButtonTitle: 'Cancel',
          cropStyle: CropStyle.circle,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
          aspectRatioPresets: [CropAspectRatioPreset.square],
        ),
      ],
    );
    if (cropped == null) return null;
    return normalizeAvatar(await cropped.readAsBytes());
  }
}

final avatarPhotoPickerProvider = Provider<AvatarPhotoPicker>(
  (ref) => NativeAvatarPhotoPicker(),
);

class AvatarEditorState {
  const AvatarEditorState({
    this.reference,
    this.bytes,
    this.busy = false,
    this.error,
    this.changed = false,
  });
  final String? reference;
  final Uint8List? bytes;
  final bool busy, changed;
  final String? error;
}

class AvatarEditor extends Notifier<AvatarEditorState> {
  late AvatarService _service;
  late String? _original;
  @override
  AvatarEditorState build() {
    _service = ref.read(avatarServiceProvider);
    _original = ref.read(accountProfileProvider).avatarUrl;
    return AvatarEditorState(reference: _original);
  }

  bool get _sameWorkspace =>
      ref.mounted &&
      ref.read(hiveServiceProvider).workspaceId == _service.hive.workspaceId;
  void select(String? reference) {
    if (state.busy) return;
    state = AvatarEditorState(
      reference: reference,
      changed: reference != _original,
    );
  }

  Future<void> pick(AvatarSource source) async {
    if (state.busy) return;
    final before = state;
    state = AvatarEditorState(
      reference: before.reference,
      bytes: before.bytes,
      changed: before.changed,
      busy: true,
    );
    try {
      final bytes = await ref.read(avatarPhotoPickerProvider).pick(source);
      if (!_sameWorkspace) return;
      state = bytes == null
          ? before
          : AvatarEditorState(
              reference: AvatarReference.photo(newCloudMutationId()),
              bytes: bytes,
              changed: true,
            );
    } catch (error) {
      if (!_sameWorkspace) return;
      debugPrint(
        '[AvatarPicker] ${source.name}: ${error.runtimeType}'
        '${error is PlatformException ? ' (${error.code})' : ''}',
      );
      final denied =
          error is PlatformException &&
          (error.code.contains('denied') || error.code.contains('restricted'));
      state = AvatarEditorState(
        reference: before.reference,
        bytes: before.bytes,
        changed: before.changed,
        error: error is MissingPluginException
            ? 'The photo picker is unavailable. Restart AEON after updating, then try again.'
            : denied
            ? 'Allow photo or camera access in your device settings, then try again.'
            : error is FormatException
            ? error.message
            : 'Could not open this picture. Try another photo.',
      );
    }
  }

  Future<bool> save() async {
    if (state.busy || !state.changed || !_sameWorkspace) return false;
    final before = state;
    state = AvatarEditorState(
      reference: before.reference,
      bytes: before.bytes,
      changed: true,
      busy: true,
    );
    try {
      await ref.read(userProfileProvider.notifier).persistSnapshot((hive) {
        if (hive.workspaceId != _service.hive.workspaceId) {
          throw StateError('Account changed.');
        }
        return _service.save(before.reference, bytes: before.bytes);
      });
      if (!_sameWorkspace) return false;
      ref.invalidate(accountProfileProvider);
      final id = AvatarReference.photoId(before.reference);
      if (id != null) ref.invalidate(avatarBytesProvider(id));
      _original = before.reference;
      state = AvatarEditorState(
        reference: before.reference,
        bytes: before.bytes,
      );
      return true;
    } catch (_) {
      if (_sameWorkspace) {
        state = AvatarEditorState(
          reference: before.reference,
          bytes: before.bytes,
          changed: true,
          error:
              'Picture could not be saved. Your previous picture is unchanged. Try again.',
        );
      }
      return false;
    }
  }
}

final avatarEditorProvider =
    NotifierProvider.autoDispose<AvatarEditor, AvatarEditorState>(
      AvatarEditor.new,
    );

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Document pickers save actual bytes; cancellation is not a successful save.
class ExportFileService {
  const ExportFileService({this.channel = const MethodChannel('leon/files')});
  final MethodChannel channel;
  Future<String?> save(String name, String mime, Uint8List bytes) =>
      channel.invokeMethod<String>('save', {
        'name': name,
        'mime': mime,
        'bytes': bytes,
      });
  Future<bool> share(String name, String mime, Uint8List bytes) async =>
      await channel.invokeMethod<bool>('share', {
        'name': name,
        'mime': mime,
        'bytes': bytes,
      }) ??
      false;
  Future<Uint8List?> pickBackup() =>
      channel.invokeMethod<Uint8List>('pickBackup');
}

final exportFileServiceProvider = Provider((ref) => const ExportFileService());

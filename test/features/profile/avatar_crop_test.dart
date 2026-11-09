import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/features/profile/providers/avatar_editor_provider.dart';
import '../../services/avatar_service_test.dart' show photoBytes;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'native crop uses circular guide, rotation controls and bounded JPEG output',
    () async {
      final directory = await Directory.systemTemp.createTemp('aeon_crop_');
      try {
        final source = await File(
          '${directory.path}/source.jpg',
        ).writeAsBytes(photoBytes());
        const channel = MethodChannel('plugins.hunghd.vn/image_cropper');
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        var cancel = false;
        messenger.setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'cropImage');
          final args = call.arguments as Map;
          expect(args['ratio_x'], 1);
          expect(args['ratio_y'], 1);
          expect(args['max_width'], 512);
          expect(args['max_height'], 512);
          expect(args['compress_format'], 'jpg');
          expect(args['android.crop_style'], 'circle');
          expect(args['android.hide_bottom_controls'], isFalse);
          expect(args['android.lock_aspect_ratio'], isTrue);
          final wheelColor = Color(
            (args['android.active_controls_widget_color'] as int) & 0xffffffff,
          );
          expect(
            1.05 / (wheelColor.computeLuminance() + .05),
            greaterThanOrEqualTo(4.5),
          );
          expect(args['ios.crop_style'], 'circle');
          expect(args['ios.rotate_button_hidden'], isFalse);
          expect(args['ios.done_button_title'], 'Use picture');
          return cancel ? null : source.path;
        });
        addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
        expect(
          await NativeAvatarPhotoPicker().cropPath(source.path),
          isNotNull,
        );
        cancel = true;
        expect(await NativeAvatarPhotoPicker().cropPath(source.path), isNull);
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}

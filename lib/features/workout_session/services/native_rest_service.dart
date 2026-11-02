import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Native alarms and actions own a durable timer identity while Dart is absent.
class NativeRestService {
  NativeRestService({this.channel = const MethodChannel('leon/rest')}) {
    if (supported) {
      channel.setMethodCallHandler((call) async {
        if (call.method == 'changed') onChanged?.call();
      });
    }
  }
  void Function()? onChanged;
  final MethodChannel channel;
  bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  Future<T?> _call<T>(String method, [Object? args]) async {
    if (!supported) return null;
    return channel.invokeMethod<T>(method, args);
  }

  Future<void> schedule(Map<String, dynamic> timer) async {
    await _call('schedule', timer);
  }

  Future<void> visible(bool visible) async {
    await _call('visible', visible);
  }

  Future<Map<String, dynamic>?> read() async {
    final value = await _call<Map>('read');
    return value == null ? null : Map<String, dynamic>.from(value);
  }

  Future<bool> complete(String timerId, {bool background = false}) async =>
      await _call<bool>('complete', {
        'timerId': timerId,
        'background': background,
      }) ??
      false;
  Future<void> cancel([String? timerId]) async {
    await _call('cancel', timerId);
  }

  Future<bool> exactAlarmsAvailable() async =>
      await _call<bool>('exactAvailable') ?? false;
  Future<void> requestExactAlarms() async {
    await _call('requestExact');
  }
}

final nativeRestServiceProvider = Provider((ref) => NativeRestService());

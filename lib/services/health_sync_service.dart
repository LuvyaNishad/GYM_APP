import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/health_tracking/models/health_import.dart';

abstract interface class HealthSyncService {
  Future<HealthAvailability> availability();
  Future<void> requestPermissions(Set<HealthMetric> metrics);
  Future<HealthReading> read(HealthMetric metric, HealthWindow window);
  Future<void> openSettings();
}

final healthSyncServiceProvider = Provider<HealthSyncService>(
  (ref) => NativeHealthSyncService(),
);

/// Foreground, read-only access. Imports never upload data or write habits.
class NativeHealthSyncService implements HealthSyncService {
  NativeHealthSyncService({MethodChannel? channel, bool? supported})
    : _channel = channel ?? const MethodChannel('leon/health'),
      _supported = supported ?? (Platform.isAndroid || Platform.isIOS);
  final MethodChannel _channel;
  final bool _supported;
  @override
  Future<HealthAvailability> availability() async {
    if (!_supported) return HealthAvailability.unsupported;
    return switch (await _channel.invokeMethod<String>('availability')) {
      'ready' => HealthAvailability.ready,
      'installRequired' => HealthAvailability.installRequired,
      _ => HealthAvailability.unsupported,
    };
  }

  @override
  Future<void> requestPermissions(Set<HealthMetric> metrics) async {
    if (!_supported || metrics.isEmpty) return;
    await _channel.invokeMethod<void>(
      'authorize',
      metrics.map((m) => m.name).toList(),
    );
  }

  @override
  Future<void> openSettings() async {
    if (_supported) await _channel.invokeMethod<void>('settings');
  }

  @override
  Future<HealthReading> read(HealthMetric metric, HealthWindow window) async {
    final raw = await _channel.invokeMapMethod<String, dynamic>('read', {
      'metric': metric.name,
      'start': window.start.millisecondsSinceEpoch,
      'end': window.end.millisecondsSinceEpoch,
    });
    if (raw == null) throw const FormatException('Missing health response');
    final intervals = raw['intervals'] as List?;
    final num? value = raw['access'] == 'denied'
        ? null
        : metric == HealthMetric.sleep && intervals != null
        ? intervals.isEmpty
              ? raw['value'] as num?
              : sleepIntervalHours(
                  intervals.map((i) {
                    final pair = i as List;
                    return HealthWindow(
                      DateTime.fromMillisecondsSinceEpoch(
                        (pair[0] as num).toInt(),
                      ),
                      DateTime.fromMillisecondsSinceEpoch(
                        (pair[1] as num).toInt(),
                      ),
                    );
                  }).toList(),
                  window,
                )
        : raw['value'] as num?;
    if (value != null && (!value.isFinite || value < 0)) {
      throw const FormatException('Invalid health value');
    }
    return HealthReading(
      state: raw['access'] == 'denied'
          ? HealthReadState.denied
          : value == null
          ? HealthReadState.noData
          : HealthReadState.data,
      access: raw['access'] == 'granted'
          ? HealthAccess.granted
          : raw['access'] == 'denied'
          ? HealthAccess.denied
          : HealthAccess.unknown,
      value: value,
      sources: List<String>.from(raw['sources'] as List? ?? const []),
      platform: raw['platform'] as String? ?? 'Health platform',
      sampleAt: raw['sampleAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (raw['sampleAt'] as num).toInt(),
            ),
      method: raw['method'] as String?,
      window: window,
    );
  }
}

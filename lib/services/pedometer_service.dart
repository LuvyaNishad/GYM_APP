/// Periodic daily step import, with a sensor fallback on unsupported phones.
///
/// Imports the same daily totals shown by Realme/OPlus Shelf every 30 seconds
/// in the foreground and on resume. Saves a single atomic snapshot for offline
/// charts. Provider totals replace previous values; sensor counts are never
/// added to them. Unsupported phones retain the existing local sensor tracker.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';

import '../core/constants/app_constants.dart';
import '../features/dashboard/models/daily_telemetry_model.dart';
import 'hive_service.dart';
import 'daily_steps_platform.dart';

/// Step tracking connection and permission status.
enum StepTrackingStatus {
  active,
  permissionDenied,
  sensorUnavailable,
  syncFailed,
  uninitialized,
}

class StepTrackingStatusNotifier extends Notifier<StepTrackingStatus> {
  @override
  StepTrackingStatus build() => StepTrackingStatus.uninitialized;

  void setStatus(StepTrackingStatus status) {
    state = status;
  }
}

/// Provider exposing the current step tracking permission and sensor status.
final stepTrackingStatusProvider =
    NotifierProvider<StepTrackingStatusNotifier, StepTrackingStatus>(
      StepTrackingStatusNotifier.new,
    );

class StepSyncInfo {
  const StepSyncInfo({this.source, this.updatedAt});
  final String? source;
  final DateTime? updatedAt;
}

class StepSyncInfoNotifier extends Notifier<StepSyncInfo> {
  @override
  StepSyncInfo build() => const StepSyncInfo();
  void update(String source, DateTime? updatedAt) =>
      state = StepSyncInfo(source: source, updatedAt: updatedAt);
}

final stepSyncInfoProvider =
    NotifierProvider<StepSyncInfoNotifier, StepSyncInfo>(
      StepSyncInfoNotifier.new,
    );

/// Provider exposing the active [PedometerService].
final pedometerServiceProvider = Provider<PedometerService>((ref) {
  final service = PedometerService(ref);
  Future.microtask(service.initialize);
  ref.onDispose(service.dispose);
  return service;
});

class PedometerService with WidgetsBindingObserver {
  PedometerService(this._ref, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Ref _ref;
  final DateTime Function() _now;
  late final DailyStepsPlatform _platform = _ref.read(
    dailyStepsPlatformProvider,
  );
  static const refreshInterval = Duration(seconds: 30);
  Timer? _refreshTimer;
  Future<void>? _refreshInFlight;
  bool _disposed = false;
  bool _initialized = false;
  bool _usingPhoneHistory = false;
  bool _foreground = true;
  static const MethodChannel _nativeChannel = MethodChannel(
    'com.example.leon/pedometer',
  );

  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  String _status = 'stopped';
  String get status => _status;

  String _currentTrackingDate = '';
  int? _bootBase;
  int _rebootOffset = 0;
  int? _lastHwReading;
  int _todayCount = 0;
  List<int> _hourlySteps = List<int>.filled(24, 0);
  Map<String, int> _historicalDays = {};
  int _recordSteps = 0;
  String _recordDate = '--';

  String _getTodayDateStr() {
    final now = _now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Initializes hardware step sensor listener, loads persisted state,
  /// and syncs with the device's native pedometer provider.
  Future<void> initialize() async {
    if (_disposed || _initialized) return;
    _initialized = true;
    _loadStateFromHive();
    _checkDateRollover();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    await _refresh(requestPermission: true);
    _startRefreshTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _refreshTimer?.cancel();
    if (_foreground && !_disposed) {
      unawaited(_refresh());
      _startRefreshTimer();
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    if (_disposed || !_foreground) return;
    _refreshTimer = Timer.periodic(
      refreshInterval,
      (_) => unawaited(_refresh()),
    );
  }

  Future<void> _refresh({bool requestPermission = false}) {
    if (_disposed) return Future.value();
    return _refreshInFlight ??= _performRefresh(requestPermission).whenComplete(
      () {
        _refreshInFlight = null;
      },
    );
  }

  Future<void> _performRefresh(bool requestPermission) async {
    _checkDateRollover();
    try {
      var allowed = await _platform.hasMotionPermission();
      if (!allowed && requestPermission && !_disposed) {
        allowed = await _platform.requestMotionPermission();
      }
      if (_disposed) return;
      if (!allowed) {
        _ref
            .read(stepTrackingStatusProvider.notifier)
            .setStatus(StepTrackingStatus.permissionDenied);
        return;
      }
      await _syncWithNativePedometer();
    } on PlatformException catch (e) {
      if (!_disposed) {
        _ref
            .read(stepTrackingStatusProvider.notifier)
            .setStatus(
              e.code == 'permission_denied'
                  ? StepTrackingStatus.permissionDenied
                  : StepTrackingStatus.syncFailed,
            );
      }
    } catch (e) {
      if (!_disposed) {
        _ref
            .read(stepTrackingStatusProvider.notifier)
            .setStatus(StepTrackingStatus.syncFailed);
      }
      debugPrint('[PedometerService] Daily step refresh failed: $e');
    }
  }

  /// Request runtime permission explicitly (e.g. from UI button or tap)
  Future<bool> requestPermission() async {
    await _refresh(requestPermission: true);
    return !_disposed &&
        _ref.read(stepTrackingStatusProvider) == StepTrackingStatus.active;
  }

  /// Synchronizes today's step count and past history with the device's native
  /// built-in step provider and queries immediate hardware sensor counter.
  Future<void> syncWithInbuiltPedometer() async {
    await _refresh();
  }

  /// Manually align today's steps with an external or user-entered value.
  /// Dynamically computes the boot base so hardware increments continue smoothly.
  Future<void> calibrateTodayBaseline(int steps) async {
    if (steps < 0) return;
    _todayCount = steps;
    if (_lastHwReading != null && _lastHwReading! > 0) {
      _bootBase = math.max(0, _lastHwReading! - _todayCount + _rebootOffset);
    }
    final isHourlyEmpty = _hourlySteps.every((e) => e == 0);
    if (isHourlyEmpty && _todayCount > 0) {
      final nowHour = DateTime.now().hour;
      final startHour = math.min(8, nowHour);
      final activeHours = math.max(1, nowHour - startHour + 1);
      final perHour = _todayCount ~/ activeHours;
      var remaining = _todayCount;
      for (int h = startHour; h <= nowHour; h++) {
        final add = (h == nowHour) ? remaining : perHour;
        _hourlySteps[h] = add;
        remaining -= add;
      }
    }
    if (_todayCount > _recordSteps) {
      _recordSteps = _todayCount;
      final now = DateTime.now();
      _recordDate = '${now.day}/${now.month}/${now.year}';
    }
    await _persistState();
    _syncTelemetry();
  }

  Future<void> _syncWithNativePedometer() async {
    final snapshot = await _platform.readDailySteps();
    if (_disposed) return;
    if (snapshot != null) {
      final today = _getTodayDateStr();
      if (snapshot.date != today) {
        throw const FormatException(
          'Step snapshot crossed midnight; retry required',
        );
      }
      final days = {
        for (final entry in _historicalDays.entries)
          if (DailyStepsSnapshot.validDate(entry.key) &&
              entry.key.compareTo(today) <= 0 &&
              entry.value >= 0)
            entry.key: entry.value,
        ...snapshot.days,
      };
      final saved = DailyStepsSnapshot(
        date: today,
        days: days,
        source: snapshot.source,
        updatedAt: _now(),
      );
      // A single checked write prevents a partially saved date/count/history.
      await _ref
          .read(hiveServiceProvider)
          .putSettingChecked(
            AppConstants.settingStepDailySnapshot,
            jsonEncode(saved.toMap()),
          );
      if (_disposed) return;
      _usingPhoneHistory = true;
      _stepCountSubscription?.cancel();
      _pedestrianStatusSubscription?.cancel();
      _stepCountSubscription = null;
      _pedestrianStatusSubscription = null;
      _currentTrackingDate = today;
      _todayCount = days[today] ?? 0;
      _hourlySteps = [];
      _historicalDays = {...days}..remove(today);
      _updateRecord(days);
      _isAvailable = true;
      _ref
          .read(stepSyncInfoProvider.notifier)
          .update(saved.source, saved.updatedAt);
      _ref
          .read(stepTrackingStatusProvider.notifier)
          .setStatus(StepTrackingStatus.active);
      _syncTelemetry();
      return;
    }
    // Do not substitute a different counter if a previously connected provider
    // becomes unavailable. Preserve the last imported daily totals for retry.
    if (_usingPhoneHistory) {
      throw StateError('Phone daily step provider is unavailable');
    }
    try {
      // Query immediate hardware sensor counter to establish real physical baseline
      final hwReading = await _nativeChannel.invokeMethod<int>(
        'getImmediateHardwareSteps',
      );
      if (hwReading != null && hwReading > 0) {
        _lastHwReading = hwReading;
        // Align bootBase so: hwReading - _bootBase + _rebootOffset == _todayCount
        _bootBase ??= math.max(0, hwReading - _todayCount + _rebootOffset);
      }

      await _persistState();
      if (_disposed) return;
      _ref
          .read(stepTrackingStatusProvider.notifier)
          .setStatus(StepTrackingStatus.active);
      _ref
          .read(stepSyncInfoProvider.notifier)
          .update('Phone step sensor', null);
      _startListening();
      _syncTelemetry();
    } catch (e) {
      debugPrint(
        '[PedometerService] Error syncing with hardware pedometer: $e',
      );
    }
  }

  /// Wipes all cached steps and historical days to start 100% clean.
  Future<void> clearAllStepData() async {
    final hive = _ref.read(hiveServiceProvider);
    await hive.deleteSettingChecked(AppConstants.settingStepDailySnapshot);
    _usingPhoneHistory = false;
    _todayCount = 0;
    _hourlySteps = List<int>.filled(24, 0);
    _historicalDays = {};
    _recordSteps = 0;
    _recordDate = '--';
    _rebootOffset = 0;
    if (_lastHwReading != null && _lastHwReading! > 0) {
      _bootBase = _lastHwReading;
    }
    await hive.putSetting(AppConstants.settingStepTodayCount, 0);
    await hive.putSetting(
      AppConstants.settingStepHourlyDistribution,
      jsonEncode(_hourlySteps),
    );
    await hive.putSetting(AppConstants.settingStepHistory, jsonEncode({}));
    await hive.putSetting(AppConstants.settingStepRecordSteps, 0);
    await hive.putSetting(AppConstants.settingStepRecordDate, '--');
    await _persistState();
    _syncTelemetry();
  }

  void _loadStateFromHive() {
    final hive = _ref.read(hiveServiceProvider);
    final todayStr = _getTodayDateStr();
    final cached = hive.getSetting<String>(
      AppConstants.settingStepDailySnapshot,
    );
    if (cached != null) {
      try {
        final snapshot = DailyStepsSnapshot.fromMap(jsonDecode(cached) as Map);
        _usingPhoneHistory = true;
        _currentTrackingDate = todayStr;
        _todayCount = snapshot.days[todayStr] ?? 0;
        _hourlySteps = [];
        _historicalDays = {...snapshot.days}..remove(todayStr);
        _updateRecord(snapshot.days);
        _ref
            .read(stepSyncInfoProvider.notifier)
            .update(snapshot.source, snapshot.updatedAt);
        _syncTelemetry();
        return;
      } catch (e) {
        debugPrint('[PedometerService] Invalid step cache: $e');
      }
    }
    final savedDate = hive.getSetting<String>(AppConstants.settingStepDate);

    _bootBase = hive.getSetting<int>(AppConstants.settingStepBootBase);
    _rebootOffset =
        hive.getSetting<int>(
          AppConstants.settingStepRebootOffset,
          fallback: 0,
        ) ??
        0;
    _lastHwReading = hive.getSetting<int>(
      AppConstants.settingStepLastHwReading,
    );
    _recordSteps =
        hive.getSetting<int>(
          AppConstants.settingStepRecordSteps,
          fallback: 0,
        ) ??
        0;
    _recordDate =
        hive.getSetting<String>(
          AppConstants.settingStepRecordDate,
          fallback: '--',
        ) ??
        '--';

    final historyRaw = hive.getSetting<String>(AppConstants.settingStepHistory);
    if (historyRaw != null && historyRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(historyRaw) as Map<String, dynamic>;
        _historicalDays = decoded.map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        );
      } catch (_) {
        _historicalDays = {};
      }
    } else {
      _historicalDays = {};
    }

    if (savedDate == todayStr) {
      _currentTrackingDate = todayStr;
      _todayCount =
          hive.getSetting<int>(
            AppConstants.settingStepTodayCount,
            fallback: 0,
          ) ??
          0;
      final hourlyRaw = hive.getSetting<String>(
        AppConstants.settingStepHourlyDistribution,
      );
      if (hourlyRaw != null && hourlyRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(hourlyRaw) as List<dynamic>;
          _hourlySteps = decoded.map((e) => (e as num).toInt()).toList();
          if (_hourlySteps.length != 24) {
            _hourlySteps = List<int>.filled(24, 0);
          }
        } catch (_) {
          _hourlySteps = List<int>.filled(24, 0);
        }
      } else {
        _hourlySteps = List<int>.filled(24, 0);
      }
    } else {
      // Different day or first launch
      if (savedDate != null && savedDate.isNotEmpty) {
        final prevCount =
            hive.getSetting<int>(
              AppConstants.settingStepTodayCount,
              fallback: 0,
            ) ??
            0;
        if (prevCount > 0) {
          _historicalDays[savedDate] = prevCount;
          if (prevCount > _recordSteps) {
            _recordSteps = prevCount;
            try {
              final parts = savedDate.split('-');
              _recordDate = '${parts[2]}/${parts[1]}/${parts[0]}';
            } catch (_) {
              _recordDate = savedDate;
            }
          }
        }
      }
      _currentTrackingDate = todayStr;
      _todayCount = 0;
      _hourlySteps = List<int>.filled(24, 0);
      _rebootOffset = 0;
      _bootBase = _lastHwReading;
      _persistState();
    }

    _syncTelemetry();
  }

  void _checkDateRollover() {
    final todayStr = _getTodayDateStr();
    if (_currentTrackingDate.isNotEmpty && _currentTrackingDate != todayStr) {
      _handleMidnightRollover(todayStr, _lastHwReading ?? 0);
    }
  }

  void _updateRecord(Map<String, int> days) {
    _recordSteps = 0;
    _recordDate = '--';
    for (final entry in days.entries) {
      if (entry.value > _recordSteps) {
        _recordSteps = entry.value;
        final parts = entry.key.split('-');
        _recordDate = '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    }
  }

  void _handleMidnightRollover(String newDateStr, int currentHwSteps) {
    if ((_todayCount > 0 || _usingPhoneHistory) &&
        _currentTrackingDate.isNotEmpty) {
      _historicalDays[_currentTrackingDate] = _todayCount;
      if (_todayCount > _recordSteps) {
        _recordSteps = _todayCount;
        try {
          final parts = _currentTrackingDate.split('-');
          _recordDate = '${parts[2]}/${parts[1]}/${parts[0]}';
        } catch (_) {
          _recordDate = _currentTrackingDate;
        }
      }
    }

    _currentTrackingDate = newDateStr;
    _todayCount = 0;
    _hourlySteps = _usingPhoneHistory ? [] : List<int>.filled(24, 0);
    _rebootOffset = 0;
    _bootBase = currentHwSteps > 0 ? currentHwSteps : null;
    if (!_usingPhoneHistory) _persistState();
    _syncTelemetry();
  }

  void _startListening() {
    if (_stepCountSubscription != null) return;

    try {
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );

      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatusChanged,
        onError: _onPedestrianStatusError,
        cancelOnError: false,
      );

      _isAvailable = true;
    } catch (e) {
      debugPrint('[PedometerService] Sensor unavailable: $e');
      _isAvailable = false;
    }
  }

  void _onStepCount(StepCount event) {
    if (_disposed || _usingPhoneHistory) return;
    _isAvailable = true;
    final rawSteps = event.steps;
    final todayStr = _getTodayDateStr();

    if (_currentTrackingDate != todayStr) {
      _handleMidnightRollover(todayStr, rawSteps);
    }

    // Detect device reboot: hardware counter reset
    if (_lastHwReading != null && rawSteps < _lastHwReading!) {
      final preRebootSteps = (_lastHwReading! - (_bootBase ?? _lastHwReading!));
      if (preRebootSteps > 0) {
        _rebootOffset += preRebootSteps;
      }
      _bootBase = rawSteps;
    }

    // If _bootBase is not set yet, align it dynamically with known _todayCount
    _bootBase ??= (rawSteps >= _todayCount)
        ? (rawSteps - _todayCount)
        : rawSteps;

    final calculatedSteps = math.max(0, rawSteps - _bootBase! + _rebootOffset);
    final delta = calculatedSteps - _todayCount;
    _lastHwReading = rawSteps;

    if (delta > 0) {
      _todayCount = calculatedSteps;
      final currentHour = DateTime.now().hour;
      if (currentHour >= 0 && currentHour < 24) {
        _hourlySteps[currentHour] += delta;
      }

      if (_todayCount > _recordSteps) {
        _recordSteps = _todayCount;
        final now = DateTime.now();
        _recordDate = '${now.day}/${now.month}/${now.year}';
      }

      _persistState();
      _syncTelemetry();
    } else if (calculatedSteps > _todayCount) {
      _todayCount = calculatedSteps;
      _persistState();
      _syncTelemetry();
    }
  }

  Future<void> _persistState() async {
    try {
      final hive = _ref.read(hiveServiceProvider);
      await hive.putSetting(AppConstants.settingStepDate, _currentTrackingDate);
      await hive.putSetting(AppConstants.settingStepTodayCount, _todayCount);
      if (_bootBase != null) {
        await hive.putSetting(AppConstants.settingStepBootBase, _bootBase);
      }
      await hive.putSetting(
        AppConstants.settingStepRebootOffset,
        _rebootOffset,
      );
      if (_lastHwReading != null) {
        await hive.putSetting(
          AppConstants.settingStepLastHwReading,
          _lastHwReading,
        );
      }
      await hive.putSetting(
        AppConstants.settingStepHourlyDistribution,
        jsonEncode(_hourlySteps),
      );
      await hive.putSetting(
        AppConstants.settingStepHistory,
        jsonEncode(_historicalDays),
      );
      await hive.putSetting(AppConstants.settingStepRecordSteps, _recordSteps);
      await hive.putSetting(AppConstants.settingStepRecordDate, _recordDate);
    } catch (e) {
      debugPrint('[PedometerService] Error persisting state: $e');
    }
  }

  void _syncTelemetry() {
    final distanceKm = double.parse(
      (_todayCount * 0.000708).toStringAsFixed(2),
    );
    final recordKm = double.parse((_recordSteps * 0.000708).toStringAsFixed(2));

    Future.microtask(() {
      if (_disposed) return;
      _ref
          .read(dailyTelemetryProvider.notifier)
          .updateDailyStepTelemetry(
            steps: _todayCount,
            distanceKm: distanceKm,
            hourlySteps: List<int>.from(_hourlySteps),
            historicalDays: Map<String, int>.from(_historicalDays),
            recordSingleDaySteps: _recordSteps,
            recordSingleDayKm: recordKm,
            recordDate: _recordDate,
          );
    });
  }

  void _onStepCountError(dynamic error) {
    if (_disposed || _usingPhoneHistory) return;
    debugPrint('[PedometerService] Step count error: $error');
    _isAvailable = false;
    _ref
        .read(stepTrackingStatusProvider.notifier)
        .setStatus(StepTrackingStatus.sensorUnavailable);
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    _status = event.status;
  }

  void _onPedestrianStatusError(dynamic error) {
    debugPrint('[PedometerService] Pedestrian status error: $error');
  }

  void dispose() {
    _disposed = true;
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
  }
}

/// Native hardware step tracker service for LEON.
///
/// Binds directly to the device's hardware step sensor (TYPE_STEP_COUNTER)
/// via the Flutter pedometer plugin. Updates the global [dailyTelemetryProvider]
/// in real time as the user walks with their phone.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';

import '../features/dashboard/models/daily_telemetry_model.dart';

/// Provider exposing the active [PedometerService].
final pedometerServiceProvider = Provider<PedometerService>((ref) {
  final service = PedometerService(ref);
  service.initialize();
  ref.onDispose(service.dispose);
  return service;
});

class PedometerService {
  PedometerService(this._ref);

  final Ref _ref;

  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  int? _initialHardwareSteps;
  late int _baseSteps;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  String _status = 'stopped';
  String get status => _status;

  /// Initializes hardware step sensor listener.
  void initialize() {
    final currentTelemetry = _ref.read(dailyTelemetryProvider);
    _baseSteps = currentTelemetry.steps;

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
    _isAvailable = true;
    if (_initialHardwareSteps == null) {
      _initialHardwareSteps = event.steps;
      return;
    }

    final delta = event.steps - _initialHardwareSteps!;
    if (delta > 0) {
      final updatedSteps = _baseSteps + delta;
      // Stride conversion: average adult stride ~ 0.708 meters per step
      final updatedKm = double.parse((updatedSteps * 0.000708).toStringAsFixed(2));
      _ref.read(dailyTelemetryProvider.notifier).updateSteps(updatedSteps, updatedKm);
    }
  }

  void _onStepCountError(dynamic error) {
    debugPrint('[PedometerService] Step count error: $error');
    _isAvailable = false;
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    _status = event.status;
  }

  void _onPedestrianStatusError(dynamic error) {
    debugPrint('[PedometerService] Pedestrian status error: $error');
  }

  void dispose() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/health_sync_service.dart';
import '../models/health_snapshot.dart';

/// Manages fetching and caching [HealthSnapshot] data from [HealthSyncService].
class HealthTrackingNotifier extends StateNotifier<AsyncValue<HealthSnapshot>> {
  HealthTrackingNotifier(this._service) : super(const AsyncValue.loading()) {
    refresh();
  }

  final HealthSyncService _service;

  /// Fetch fresh health data from the wearable / health platform.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final snapshot = await _service.fetchLatestSnapshot();
      state = AsyncValue.data(snapshot);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}

/// Global provider for Health Tracking, injecting [NoOpHealthSyncService]
/// until a real wearable integration is configured.
final healthTrackingProvider =
    StateNotifierProvider<HealthTrackingNotifier, AsyncValue<HealthSnapshot>>(
  (ref) => HealthTrackingNotifier(const NoOpHealthSyncService()),
);

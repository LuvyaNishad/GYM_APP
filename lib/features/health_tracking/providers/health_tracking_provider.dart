import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/health_sync_service.dart';
import '../models/health_snapshot.dart';

/// Fetches and caches [HealthSnapshot] data from [HealthSyncService].
///
/// Injected with [NoOpHealthSyncService] until a real wearable integration is
/// configured; swapping in a live service means changing
/// [healthSyncServiceProvider] only.
class HealthTrackingNotifier extends AsyncNotifier<HealthSnapshot> {
  @override
  Future<HealthSnapshot> build() {
    final service = ref.watch(healthSyncServiceProvider);
    return service.fetchLatestSnapshot();
  }

  /// Fetch fresh health data from the wearable / health platform.
  void refresh() => ref.invalidateSelf();
}

/// Global provider for Health Tracking.
final healthTrackingProvider =
    AsyncNotifierProvider<HealthTrackingNotifier, HealthSnapshot>(
  HealthTrackingNotifier.new,
);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/health_tracking_provider.dart';
import '../widgets/health_metric_card.dart';

/// Health Tracking dashboard screen.
///
/// Surfaces wearable & manual health data: steps, heart rate, sleep,
/// and active calories pulled from [HealthSyncService].
class HealthTrackingScreen extends ConsumerWidget {
  const HealthTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(healthTrackingProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'HEALTH TRACKING',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            tooltip: 'Sync wearable data',
            onPressed: () =>
                ref.read(healthTrackingProvider.notifier).refresh(),
          ),
        ],
      ),
      body: snapshotAsync.when(
        data: (snapshot) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(label: 'TODAY', timestamp: snapshot.recordedAt),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: HealthMetricCard(
                    label: 'STEPS',
                    value: snapshot.steps != null ? '${snapshot.steps}' : '--',
                    unit: 'steps',
                    icon: Icons.directions_walk_outlined,
                    accentColor: const Color(0xFF69FF47),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HealthMetricCard(
                    label: 'HEART RATE',
                    value: snapshot.heartRateBpm != null
                        ? '${snapshot.heartRateBpm}'
                        : '--',
                    unit: 'bpm',
                    icon: Icons.favorite_border_outlined,
                    accentColor: const Color(0xFFFF4E6A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: HealthMetricCard(
                    label: 'SLEEP',
                    value: snapshot.sleepHours != null
                        ? snapshot.sleepHours!.toStringAsFixed(1)
                        : '--',
                    unit: 'hrs',
                    icon: Icons.bedtime_outlined,
                    accentColor: const Color(0xFF7B61FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HealthMetricCard(
                    label: 'CALORIES',
                    value: snapshot.activeCalories != null
                        ? '${snapshot.activeCalories}'
                        : '--',
                    unit: 'kcal',
                    icon: Icons.local_fire_department_outlined,
                    accentColor: const Color(0xFFFF6B35),
                  ),
                ),
              ],
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error syncing health data: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.timestamp});
  final String label;
  final DateTime? timestamp;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 11,
            color: Colors.white38,
            letterSpacing: 2,
          ),
        ),
        if (timestamp != null)
          Text(
            'SYNCED ${_formatTime(timestamp!)}',
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 9,
              color: Colors.white24,
              letterSpacing: 1,
            ),
          ),
      ],
    );
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

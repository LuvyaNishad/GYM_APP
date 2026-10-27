/// Health Tracking & Body Recomposition Screen for LEON.
///
/// Features:
/// - Tab 0: Daily Wearable Metrics (Steps, Heart Rate, Sleep, Active Calories)
/// - Tab 1: Recomposition & Body Measurement Tracker (Waist, Arms, Chest, Thighs, BF%, 30-day deltas)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/sync_status_indicator.dart';
import '../models/body_measurement_model.dart';
import '../providers/body_measurements_provider.dart';
import '../providers/health_tracking_provider.dart';
import '../widgets/health_metric_card.dart';
import '../widgets/log_measurement_sheet.dart';

class HealthTrackingScreen extends ConsumerStatefulWidget {
  const HealthTrackingScreen({super.key});

  @override
  ConsumerState<HealthTrackingScreen> createState() =>
      _HealthTrackingScreenState();
}

class _HealthTrackingScreenState extends ConsumerState<HealthTrackingScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(healthTrackingProvider);
    final recomposition = ref.watch(recompositionSummaryProvider);
    final measurements = ref.watch(bodyMeasurementsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'HEALTH & MEASUREMENTS',
          style: AppTypography.headlineSmall.copyWith(
            fontSize: 16.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: AppColors.pureWhite,
          ),
        ),
        actions: [
          const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 4),
              child: SyncStatusIndicator(showLabel: true),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00E5FF)),
            tooltip: 'Sync wearable data',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(healthTrackingProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Top Segment Switcher ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.steel.withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTabIndex = 0);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0
                              ? const Color(0xFF00E5FF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'DAILY METRICS',
                            style: TextStyle(
                              fontFamily: AppTypography.fontBody,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _selectedTabIndex == 0
                                  ? AppColors.onyx
                                  : AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTabIndex = 1);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1
                              ? const Color(0xFF00E5FF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'RECOMPOSITION',
                            style: TextStyle(
                              fontFamily: AppTypography.fontBody,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _selectedTabIndex == 1
                                  ? AppColors.onyx
                                  : AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tab Content ──────────────────────────────────────────────────
          Expanded(
            child: _selectedTabIndex == 0
                ? snapshotAsync.when(
                    data: (snapshot) => ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _SectionHeader(
                            label: 'TODAY', timestamp: snapshot.recordedAt),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: HealthMetricCard(
                                label: 'STEPS',
                                value: snapshot.steps != null
                                    ? '${snapshot.steps}'
                                    : '--',
                                unit: 'steps',
                                icon: Icons.directions_walk_outlined,
                                accentColor: const Color(0xFF00E5FF),
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
                                accentColor: AppColors.warning,
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
                                accentColor: const Color(0xFFFFB300),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    loading: () => const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF00E5FF)),
                    ),
                    error: (err, _) => Center(
                      child: Text(
                        'Error syncing health data: $err',
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  )
                : _buildRecompositionView(context, recomposition, measurements),
          ),
        ],
      ),
    );
  }

  Widget _buildRecompositionView(
    BuildContext context,
    RecompositionSummary summary,
    List<BodyMeasurementEntry> measurements,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      physics: const BouncingScrollPhysics(),
      children: [
        // ── 1. Hero Recomposition Card ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.steel.withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'BODY COMPOSITION CHECK-IN',
                    style: TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      LogMeasurementSheet.show(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: AppColors.onyx,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text(
                      'LOG',
                      style: TextStyle(
                        fontFamily: AppTypography.fontBody,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'WEIGHT',
                      value: summary.latestWeight > 0
                          ? '${summary.latestWeight}'
                          : '--',
                      unit: summary.latestWeight > 0 ? 'KG' : '',
                      delta: summary.latestWeight > 0
                          ? (summary.weightDelta30d != 0
                              ? '${summary.weightDelta30d > 0 ? '+' : ''}${summary.weightDelta30d} kg'
                              : 'STABLE')
                          : 'NO DATA',
                      isPositiveBetter: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'EST. BODY FAT',
                      value: summary.latestBodyFat != null
                          ? '${summary.latestBodyFat}%'
                          : '--',
                      unit: '',
                      delta: summary.bodyFatDelta30d != null
                          ? '${summary.bodyFatDelta30d! > 0 ? '+' : ''}${summary.bodyFatDelta30d}%'
                          : 'NO DATA',
                      isPositiveBetter: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── 2. Circumference Grid ───────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _buildCircumferenceCard(
                label: 'WAIST',
                value: summary.latestWaist != null
                    ? '${summary.latestWaist} cm'
                    : '--',
                delta: summary.waistDelta30d != null
                    ? '${summary.waistDelta30d! > 0 ? '+' : ''}${summary.waistDelta30d} cm (30d)'
                    : null,
                icon: Icons.straighten_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCircumferenceCard(
                label: 'ARMS (FLEXED)',
                value: summary.latestArms != null
                    ? '${summary.latestArms} cm'
                    : '--',
                delta: summary.armDelta30d != null
                    ? '${summary.armDelta30d! > 0 ? '+' : ''}${summary.armDelta30d} cm (30d)'
                    : null,
                icon: Icons.fitness_center_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildCircumferenceCard(
                label: 'CHEST',
                value: summary.latestChest != null
                    ? '${summary.latestChest} cm'
                    : '--',
                delta: summary.chestDelta30d != null
                    ? '${summary.chestDelta30d! > 0 ? '+' : ''}${summary.chestDelta30d} cm (30d)'
                    : null,
                icon: Icons.shield_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCircumferenceCard(
                label: 'THIGHS',
                value: measurements.isNotEmpty && measurements.first.thighsCm != null
                    ? '${measurements.first.thighsCm} cm'
                    : '--',
                delta: 'STABLE (30d)',
                icon: Icons.directions_walk_rounded,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── 3. Measurement History List ─────────────────────────────────────
        const Text(
          'MEASUREMENT LOG HISTORY',
          style: TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),

        if (measurements.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.steel.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: const [
                Icon(
                  Icons.straighten_rounded,
                  size: 28,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 10),
                Text(
                  'NO MEASUREMENTS LOGGED',
                  style: TextStyle(
                    fontFamily: AppTypography.fontBody,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pureWhite,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Tap "Log Measurement" above to track weight, body fat, and body circumferences over time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.fontBody,
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          for (final m in measurements) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.steel.withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(m.date),
                      style: const TextStyle(
                        fontFamily: AppTypography.fontMono,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${m.weightKg} KG · ${m.bodyFatPercent ?? '--'}% BF',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontMono,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pureWhite,
                      ),
                    ),
                    if (m.notes != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        m.notes!,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontBody,
                          fontSize: 11.5,
                          color: AppColors.platinum,
                        ),
                      ),
                    ],
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  tooltip: 'Delete Check-in',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(bodyMeasurementsProvider.notifier)
                        .deleteMeasurement(m.id);
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String unit,
    required String delta,
    required bool isPositiveBetter,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.onyx,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.steel.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTypography.fontMono,
              fontSize: 11.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: AppTypography.fontMono,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.pureWhite,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontMono,
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            delta,
            style: const TextStyle(
              fontFamily: AppTypography.fontMono,
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
              color: Color(0xFF00E5FF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircumferenceCard({
    required String label,
    required String value,
    String? delta,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.steel.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTypography.fontMono,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(icon, size: 16, color: const Color(0xFF00E5FF)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTypography.fontMono,
              fontSize: 16.0,
              fontWeight: FontWeight.w800,
              color: AppColors.pureWhite,
            ),
          ),
          if (delta != null) ...[
            const SizedBox(height: 4),
            Text(
              delta,
              style: const TextStyle(
                fontFamily: AppTypography.fontMono,
                fontSize: 11.0,
                color: Color(0xFF00E5FF),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
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
            fontFamily: AppTypography.fontMono,
            fontSize: 11.0,
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        if (timestamp != null)
          Text(
            'SYNCED ${_formatTime(timestamp!)}',
            style: const TextStyle(
              fontFamily: AppTypography.fontMono,
              fontSize: 11.0,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
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

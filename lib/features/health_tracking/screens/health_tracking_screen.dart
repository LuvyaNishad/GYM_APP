library;

import '../../../core/utils/measurement_units.dart';

/// Health Tracking & Body Recomposition Screen for LEON.
///
/// Features:
/// - Tab 0: Daily Wearable Metrics (Steps, Heart Rate, Sleep, Active Calories)
/// - Tab 1: Recomposition & Body Measurement Tracker (Waist, Arms, Chest, Thighs, BF%, 30-day deltas)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/sync_status_indicator.dart';
import '../models/body_measurement_model.dart';
import '../providers/body_measurements_provider.dart';
import '../../../shared/widgets/persistence_feedback.dart';
import '../providers/health_tracking_provider.dart';
import '../widgets/health_metric_card.dart';
import '../widgets/health_connection_card.dart';
import '../../dashboard/models/daily_telemetry_model.dart';
import '../models/health_import.dart';
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
    final snapshot = ref.watch(healthTrackingProvider);
    final metrics = ref.watch(dailyTelemetryProvider);
    final imported = ref.watch(currentHealthImportProvider);
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
            letterSpacing: 1.5,
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
            tooltip: 'Refresh health data',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(healthImportProvider.notifier).refresh();
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
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const HealthConnectionCard(),
                      const SizedBox(height: 16),
                      _SectionHeader(
                        label: 'DAILY TOTALS',
                        timestamp: imported?.refreshedAt,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: HealthMetricCard(
                              label: 'STEPS',
                              caption: metrics.stepsSource ?? 'Phone tracker',
                              value: snapshot.steps != null
                                  ? '${snapshot.steps}'
                                  : '--',
                              unit: 'steps',
                              icon: Icons.directions_walk_outlined,
                              accentColor: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: HealthMetricCard(
                              label: 'HEART RATE',
                              caption:
                                  imported
                                          ?.reading(HealthMetric.heartRate)
                                          .value !=
                                      null
                                  ? imported!
                                        .reading(HealthMetric.heartRate)
                                        .platform
                                  : 'No readable sample today',
                              value: snapshot.heartRateBpm != null
                                  ? '${snapshot.heartRateBpm}'
                                  : '--',
                              unit: 'bpm',
                              icon: Icons.favorite_border_outlined,
                              accentColor: AppColors.textPrimary,
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
                              caption: metrics.sleepSource ?? 'No sleep logged',
                              value: snapshot.sleepHours != null
                                  ? snapshot.sleepHours!.toStringAsFixed(1)
                                  : '--',
                              unit: 'hrs',
                              icon: Icons.bedtime_outlined,
                              accentColor: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: HealthMetricCard(
                              label: 'CALORIES',
                              caption:
                                  metrics.caloriesSource ??
                                  'No active burn logged',
                              value: snapshot.activeCalories != null
                                  ? '${snapshot.activeCalories}'
                                  : '--',
                              unit: 'active kcal',
                              icon: Icons.local_fire_department_outlined,
                              accentColor: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
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
    final units = ref.watch(measurementUnitsProvider);
    String change(double? value, {bool weight = false, bool percent = false}) {
      if (value == null) return 'Not enough data';
      final display = percent
          ? value
          : weight
          ? units.weightFromKg(value)
          : units.heightFromCm(value);
      return '${display > 0 ? '+' : ''}${display.toStringAsFixed(1)} ${percent
          ? '%'
          : weight
          ? units.weightLabel
          : units.heightInputLabel}';
    }

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
                        horizontal: 10,
                        vertical: 6,
                      ),
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
                          ? units
                                .weightFromKg(summary.latestWeight)
                                .toStringAsFixed(1)
                          : '--',
                      unit: summary.latestWeight > 0 ? units.weightLabel : '',
                      delta: change(summary.weightDelta30d, weight: true),
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
                      delta: change(summary.bodyFatDelta30d, percent: true),
                      isPositiveBetter: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            summary.comparisonDays == null
                ? 'For a monthly comparison, log a recent measurement and one from about 30 days ago.'
                : 'Change over ${summary.comparisonDays} days, using a baseline near 30 days ago.',
            style: AppTypography.bodySmall,
          ),
        ),
        const SizedBox(height: 14),

        // ── 2. Circumference Grid ───────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _buildCircumferenceCard(
                label: 'WAIST',
                value: units.length(summary.latestWaist),
                delta: change(summary.waistDelta30d),
                icon: Icons.straighten_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCircumferenceCard(
                label: 'ARMS (FLEXED)',
                value: units.length(summary.latestArms),
                delta: change(summary.armDelta30d),
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
                value: units.length(summary.latestChest),
                delta: change(summary.chestDelta30d),
                icon: Icons.shield_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCircumferenceCard(
                label: 'THIGHS',
                value: units.length(summary.latestThighs),
                delta: change(summary.thighDelta30d),
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
              border: Border.all(color: AppColors.steel.withValues(alpha: 0.4)),
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
                        '${units.weight(m.weightKg)} · ${m.bodyFatPercent ?? '--'}% BF',
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
                    onPressed: () async {
                      final success = await persistWithFeedback(
                        context,
                        () => ref
                            .read(bodyMeasurementsProvider.notifier)
                            .deleteMeasurement(m.id),
                        message:
                            'Could not delete the check-in. Please try again.',
                      );
                      if (success) HapticFeedback.selectionClick();
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
        border: Border.all(color: AppColors.steel.withValues(alpha: 0.4)),
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
        border: Border.all(color: AppColors.steel.withValues(alpha: 0.4)),
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
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
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
    return Wrap(
      spacing: 16,
      runSpacing: 8,
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
            'CHECKED ${_formatTime(timestamp!)}',
            style: const TextStyle(
              fontFamily: AppTypography.fontMono,
              fontSize: 11.0,
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
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

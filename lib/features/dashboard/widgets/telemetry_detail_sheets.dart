/// LEON Daily Telemetry Detail Bottom Sheets.
///
/// Provides deep inspection popups for:
/// 1. Step Count (Hourly distribution, peak tooltips, distance)
/// 2. Calories (Active vs resting burn, goal completion)
/// 3. Hydration (Live water logging: +250ml, +500ml, undo)
/// 4. Sleep (Quality rating, sleep stages breakdown, recovery readiness)
///
/// Designed per Apple HIG & Noguchi Minimalist Palette with useRootNavigator.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/daily_telemetry_model.dart';

/// Shows the Step Count details modal sheet.
void showStepsDetailSheet(BuildContext context, DailyTelemetry telemetry) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TelemetrySheetContainer(
      child: _StepsDetailContent(telemetry: telemetry),
    ),
  );
}

/// Shows the Calories details modal sheet.
void showCaloriesDetailSheet(BuildContext context, DailyTelemetry telemetry) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TelemetrySheetContainer(
      child: _CaloriesDetailContent(telemetry: telemetry),
    ),
  );
}

/// Shows the Hydration details modal sheet.
void showHydrationDetailSheet(BuildContext context, DailyTelemetry telemetry) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TelemetrySheetContainer(
      child: const _HydrationDetailContent(),
    ),
  );
}

/// Shows the Sleep details modal sheet.
void showSleepDetailSheet(BuildContext context, DailyTelemetry telemetry) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TelemetrySheetContainer(
      child: _SleepDetailContent(telemetry: telemetry),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BASE SHEET CONTAINER
// ─────────────────────────────────────────────────────────────────────────────

class _TelemetrySheetContainer extends StatelessWidget {
  const _TelemetrySheetContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141722),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 36,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab notch
            Center(
              child: Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.steel,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. STEP COUNT DETAIL CONTENT
// ─────────────────────────────────────────────────────────────────────────────

class _StepsDetailContent extends StatelessWidget {
  const _StepsDetailContent({required this.telemetry});

  final DailyTelemetry telemetry;

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final t = telemetry;
    final progressPct = (t.stepsProgress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.directions_walk_rounded,
                  color: AppColors.pureWhite,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Step Count',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: AppColors.platinum, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'DAILY ACTIVITY & MOVEMENT',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),

        // Hero Stat
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _formatNumber(t.steps),
              style: AppTypography.headlineLarge.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.pureWhite,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'STEPS',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.platinum,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.steel),
              ),
              child: Text(
                '$progressPct% of ${t.stepsGoal ~/ 1000}k goal',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: t.stepsProgress,
            backgroundColor: AppColors.steel,
            valueColor: const AlwaysStoppedAnimation(AppColors.pureWhite),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 20),

        // 3 Secondary Metrics
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'DISTANCE',
                value: '${t.distanceKm} km',
                icon: Icons.navigation_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'ACTIVE TIME',
                value: '1h 24m',
                icon: Icons.timer_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'BURN',
                value: '385 kcal',
                icon: Icons.local_fire_department_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Detailed hourly chart
        Text(
          'HOURLY DISTRIBUTION',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.platinum,
            letterSpacing: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.steel),
          ),
          child: _DetailedHourlyBarChart(hourlySteps: t.hourlySteps),
        ),
      ],
    );
  }
}

class _DetailedHourlyBarChart extends StatelessWidget {
  const _DetailedHourlyBarChart({required this.hourlySteps});

  final List<int> hourlySteps;

  @override
  Widget build(BuildContext context) {
    if (hourlySteps.isEmpty) return const SizedBox.shrink();
    final maxVal = hourlySteps.reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < hourlySteps.length; i++) ...[
                Flexible(
                  child: FractionallySizedBox(
                    heightFactor: (hourlySteps[i] / (maxVal > 0 ? maxVal : 1)).clamp(0.08, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: hourlySteps[i] == maxVal ? AppColors.pureWhite : AppColors.steel,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                if (i < hourlySteps.length - 1) const SizedBox(width: 4),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('08:00', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            Text('12:00', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            Text('16:00', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            Text('20:00', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. CALORIES DETAIL CONTENT
// ─────────────────────────────────────────────────────────────────────────────

class _CaloriesDetailContent extends StatelessWidget {
  const _CaloriesDetailContent({required this.telemetry});

  final DailyTelemetry telemetry;

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final t = telemetry;
    final progressPct = (t.caloriesProgress * 100).toInt();
    final remaining = math.max(0, t.caloriesGoal - t.calories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.pureWhite,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Calories',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: AppColors.platinum, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'ACTIVE ENERGY & BASAL METABOLISM',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatNumber(t.calories),
                  style: AppTypography.headlineLarge.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.pureWhite,
                  ),
                ),
                Text(
                  'KCAL BURNED',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.platinum,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$remaining kcal remaining to goal',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            // Circular progress mini gauge
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: t.caloriesProgress,
                    backgroundColor: AppColors.steel,
                    color: AppColors.pureWhite,
                    strokeWidth: 7,
                  ),
                  Text(
                    '$progressPct%',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontMono,
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Split breakdown
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'ACTIVE BURN',
                value: '1,740 kcal',
                icon: Icons.fitness_center_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'BASAL (BMR)',
                value: '650 kcal',
                icon: Icons.favorite_border_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'DAILY GOAL',
                value: '${_formatNumber(t.caloriesGoal)} kcal',
                icon: Icons.flag_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. HYDRATION DETAIL CONTENT (WITH INTERACTIVE WATER LOGGING)
// ─────────────────────────────────────────────────────────────────────────────

class _HydrationDetailContent extends ConsumerWidget {
  const _HydrationDetailContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dailyTelemetryProvider);
    final progressPct = (t.waterProgress * 100).toInt();
    final liters = (t.waterMl / 1000).toStringAsFixed(2);
    final goalLiters = (t.waterGoalMl / 1000).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.water_drop_rounded,
                  color: AppColors.pureWhite,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Hydration',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: AppColors.platinum, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'WATER INTAKE & FLUID BALANCE',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              liters,
              style: AppTypography.headlineLarge.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.pureWhite,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'LITERS',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.platinum,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.steel),
              ),
              child: Text(
                '$progressPct% of $goalLiters L goal',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: t.waterProgress,
            backgroundColor: AppColors.steel,
            valueColor: const AlwaysStoppedAnimation(AppColors.pureWhite),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'RAPID WATER LOGGING',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.platinum,
            letterSpacing: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Quick log pill buttons
        Row(
          children: [
            Expanded(
              child: _LogButton(
                title: '+250 ml',
                subtitle: 'Glass',
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(dailyTelemetryProvider.notifier).logWater(250);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LogButton(
                title: '+500 ml',
                subtitle: 'Shaker',
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(dailyTelemetryProvider.notifier).logWater(500);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LogButton(
                title: '-250 ml',
                subtitle: 'Undo',
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(dailyTelemetryProvider.notifier).logWater(-250);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LogButton extends StatelessWidget {
  const _LogButton({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.steel),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTypography.fontBody,
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pureWhite,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. SLEEP DETAIL CONTENT
// ─────────────────────────────────────────────────────────────────────────────

class _SleepDetailContent extends StatelessWidget {
  const _SleepDetailContent({required this.telemetry});

  final DailyTelemetry telemetry;

  @override
  Widget build(BuildContext context) {
    final t = telemetry;
    final progressPct = (t.sleepProgress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bedtime_rounded,
                  color: AppColors.pureWhite,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sleep',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: AppColors.platinum, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'REST ARCHITECTURE & RECOVERY',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${t.sleepHours}',
              style: AppTypography.headlineLarge.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.pureWhite,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'HOURS',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.platinum,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.steel),
              ),
              child: Text(
                '$progressPct% of ${t.sleepGoalHours.toInt()}h target',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: t.sleepProgress,
            backgroundColor: AppColors.steel,
            valueColor: const AlwaysStoppedAnimation(AppColors.pureWhite),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 20),

        // Sleep stages breakdown
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'DEEP SLEEP',
                value: '1h 45m',
                icon: Icons.waves_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'REM SLEEP',
                value: '1h 55m',
                icon: Icons.remove_red_eye_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'SCORE',
                value: '88% Optimal',
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE METRIC TILE
// ─────────────────────────────────────────────────────────────────────────────

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.steel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.platinum),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTypography.fontMono,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: AppColors.pureWhite,
            ),
          ),
        ],
      ),
    );
  }
}

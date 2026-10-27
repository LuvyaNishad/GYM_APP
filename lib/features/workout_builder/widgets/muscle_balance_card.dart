import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import 'muscle_radar_chart.dart';

class MuscleBalanceCard extends StatefulWidget {
  const MuscleBalanceCard({
    super.key,
    required this.plannedVolume,
    required this.loggedVolume,
    this.onAutoTuneMuscle,
  });
  final Map<String, int> plannedVolume, loggedVolume;
  final void Function(String muscle)? onAutoTuneMuscle;
  @override
  State<MuscleBalanceCard> createState() => _MuscleBalanceCardState();
}

class _MuscleBalanceCardState extends State<MuscleBalanceCard> {
  bool _chart = false;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    final local = MaterialLocalizations.of(context);
    final keys = {
      ...MuscleRadarChart.kAxes,
      ...widget.plannedVolume.keys,
      ...widget.loggedVolume.keys,
    }.toList();
    final hasLogs = widget.loggedVolume.values.any((v) => v > 0);
    final maxSets = [
      ...widget.plannedVolume.values,
      ...widget.loggedVolume.values,
    ].fold<int>(1, (a, b) => a > b ? a : b);
    return GlassCard(
      border: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MUSCLE BALANCE', style: AppTypography.headlineSmall),
          const SizedBox(height: 6),
          Text(
            '${local.formatMediumDate(start)} – ${local.formatMediumDate(end)}',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Logged working sets against your full-week plan. Warmups are excluded.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Sets'),
                icon: Icon(Icons.bar_chart_rounded),
              ),
              ButtonSegment(
                value: true,
                label: Text('Radar'),
                icon: Icon(Icons.radar_rounded),
              ),
            ],
            selected: {_chart},
            onSelectionChanged: (s) => setState(() => _chart = s.first),
          ),
          const SizedBox(height: 16),
          if (!hasLogs)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'No working sets logged this week. Your plan is a guide; there is no deficit to fix.',
                style: AppTypography.bodyMedium,
              ),
            ),
          if (_chart)
            Center(
              child: FittedBox(
                child: MuscleRadarChart(
                  plannedVolume: widget.plannedVolume,
                  loggedVolume: widget.loggedVolume,
                  size: 290,
                  maxSetsScale: maxSets.toDouble(),
                ),
              ),
            ),
          if (!_chart) ...[
            for (final muscle in keys)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(muscle, style: AppTypography.bodyMedium),
                        ),
                        Text(
                          '${widget.loggedVolume[muscle] ?? 0} / ${widget.plannedVolume[muscle] ?? 0} sets',
                          style: AppTypography.monoSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: ((widget.loggedVolume[muscle] ?? 0) / maxSets)
                          .clamp(0, 1),
                      minHeight: 4,
                      color: AppColors.platinum,
                      backgroundColor: AppColors.steel,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
          ],
          if (widget.onAutoTuneMuscle != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                onPressed: () => widget.onAutoTuneMuscle!(keys.first),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('REVIEW PLAN'),
              ),
            ),
        ],
      ),
    );
  }
}

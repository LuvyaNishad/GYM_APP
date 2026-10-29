import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/muscle_spider_chart.dart';
import '../models/muscle_workload.dart';

class MuscleWorkloadChart extends StatelessWidget {
  const MuscleWorkloadChart({
    super.key,
    required this.workload,
    required this.maxSets,
    this.height = 282,
    this.paintKey,
    this.weekly = false,
  });
  final MuscleWorkload workload;
  final double maxSets, height;
  final Key? paintKey;
  final bool weekly;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      MuscleSpiderChart(
        height: height,
        paintKey: paintKey,
        series: [
          if (workload.hasPlan)
            SpiderChartSeries(
              values: [
                for (final muscle in workload.muscles) muscle.planned / maxSets,
              ],
              color: AppColors.platinum,
              filled: false,
            ),
          SpiderChartSeries(
            values: [
              for (final muscle in workload.muscles) muscle.completed / maxSets,
            ],
          ),
        ],
        captions: {
          for (final muscle in workload.muscles)
            muscle.name: '${formatSetEquivalents(muscle.completed)} eq',
        },
        semanticLabel:
            'Muscle workload. ${workload.muscles.map((m) => '${m.name}: ${formatSetEquivalents(m.completed)} working-set equivalents').join('. ')}',
        detailBuilder: (context, category) => _MuscleDetail(
          muscle: workload.muscles.firstWhere((m) => m.name == category),
          hasPlan: workload.hasPlan,
          weekly: weekly,
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          const Text('Filled area = work done', style: _caption),
          if (workload.hasPlan)
            const Text('Dashed arc = target', style: _caption),
        ],
      ),
      const SizedBox(height: 5),
      Text(
        'Full sector = ${formatSetEquivalents(maxSets)} set equivalents',
        style: _caption,
      ),
      if (workload.unmappedSets > 0) ...[
        const SizedBox(height: 8),
        Text(
          '${workload.unmappedSets} working sets have no muscle assignment and are excluded from the shape.',
          style: _caption,
        ),
      ],
    ],
  );
}

const _caption = TextStyle(
  fontFamily: 'Outfit',
  fontSize: 11,
  color: AppColors.textMuted,
);

class _MuscleDetail extends StatelessWidget {
  const _MuscleDetail({
    required this.muscle,
    required this.hasPlan,
    required this.weekly,
  });
  final MuscleWorkloadEntry muscle;
  final bool hasPlan;
  final bool weekly;

  @override
  Widget build(BuildContext context) {
    final hasTarget = hasPlan && muscle.planned > 0;
    final remaining = muscle.planned - muscle.completed;
    final String insight;
    if (hasTarget) {
      insight = remaining > .01
          ? weekly
                ? '${formatSetEquivalents(remaining)} eq remaining in the full-week target.'
                : '${formatSetEquivalents(remaining)} eq below the planned target.'
          : 'Planned workload reached for this muscle.';
    } else if (muscle.completed <= 0) {
      insight = 'No work logged for this muscle in this view.';
    } else if (muscle.direct == 0) {
      insight = 'Supporting work from other exercises.';
    } else {
      insight =
          'Direct training${muscle.supporting > 0 ? ' plus supporting work' : ''}. Tap another muscle to compare.';
    }
    return Container(
      key: const ValueKey('muscle-workload-detail'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141A23),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: .22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${muscle.name.toUpperCase()} WORKLOAD',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Text(
                formatSetEquivalents(muscle.completed),
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 5),
              const Text('eq', style: _caption),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _DetailValue(
                label: 'Direct sets',
                value: formatSetEquivalents(muscle.direct),
              ),
              _DetailValue(
                label: 'Support eq',
                value: formatSetEquivalents(muscle.supporting),
              ),
              if (hasTarget)
                _DetailValue(
                  label: weekly ? 'Weekly target' : 'Planned eq',
                  value: formatSetEquivalents(muscle.planned),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insight,
            style: _caption.copyWith(
              color: hasTarget && remaining > .01
                  ? AppColors.warning
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: _caption),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../recovery/screens/recovery_screen.dart';

class RecoveryStatusWidget extends StatelessWidget {
  const RecoveryStatusWidget({
    super.key,
    this.isReady,
    this.readinessScore,
    this.hrvMs,
    this.restingBpm,
  });
  final bool? isReady;
  final int? readinessScore, hrvMs, restingBpm;
  @override
  Widget build(BuildContext context) => GlassCard(
    blur: true,
    onTap: () => context.push(AppConstants.routeRecovery),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'RECOVERY CHECK-IN',
                style: AppTypography.headlineSmall,
              ),
            ),
            IconButton(
              tooltip: 'Recovery information',
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (dialog) => AlertDialog(
                  title: const Text('RECOVERY READINESS'),
                  content: const Text(recoveryExplanation),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialog).pop(),
                      child: const Text('UNDERSTOOD'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Text(
          readinessScore == null
              ? 'Log sleep, hydration and soreness'
              : 'Self-check estimate: $readinessScore/100',
          style: AppTypography.bodyMedium,
        ),
      ],
    ),
  );
}

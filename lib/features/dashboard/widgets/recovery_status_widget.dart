import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
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
    sharedBackdrop: true,
    repaintBoundary: true,
    blur: true,
    padding: const EdgeInsets.all(12),
    onTap: () => context.push(AppConstants.routeRecovery),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'RECOVERY CHECK-IN',
                style: AppTypography.headlineSmall.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 5),
              Text(
                readinessScore == null
                    ? 'Log sleep, hydration and soreness'
                    : 'Self-check estimate: $readinessScore/100',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.platinum,
                ),
              ),
            ],
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
  );
}

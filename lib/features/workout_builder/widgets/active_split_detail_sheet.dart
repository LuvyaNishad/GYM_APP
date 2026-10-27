import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../providers/splits_provider.dart';
import '../providers/weekly_volume_provider.dart';
import 'create_routine_sheet.dart';
import 'muscle_balance_card.dart';

void showActiveSplitDetailSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ActivePlanDetails(),
    );

class _ActivePlanDetails extends ConsumerWidget {
  const _ActivePlanDetails();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(splitsProvider);
    return AppSheet(
      title: state.activeSplit.name,
      children: [
        MuscleBalanceCard(
          plannedVolume: plannedWeeklyMuscleSets(state.activeSplit),
          loggedVolume: state.loggedVolume,
          onAutoTuneMuscle: (_) =>
              showCreateRoutineSheet(context, initialSplit: state.activeSplit),
        ),
      ],
    );
  }
}

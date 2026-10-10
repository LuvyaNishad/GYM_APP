import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/split_model.dart';

/// Bottom sheet modal to switch active training splits with impact preview.
class SwitchSplitBottomSheet extends StatefulWidget {
  const SwitchSplitBottomSheet({
    super.key,
    required this.splits,
    required this.activeSplitId,
    required this.onSplitSelected,
  });

  final List<TrainingSplitModel> splits;
  final String activeSplitId;
  final ValueChanged<String> onSplitSelected;

  @override
  State<SwitchSplitBottomSheet> createState() => _SwitchSplitBottomSheetState();
}

class _SwitchSplitBottomSheetState extends State<SwitchSplitBottomSheet> {
  late String _selectedSplitId;

  @override
  void initState() {
    super.initState();
    _selectedSplitId = widget.activeSplitId;
  }

  @override
  Widget build(BuildContext context) {
    final currentSplit =
        widget.splits.firstWhere((s) => s.id == widget.activeSplitId);
    final targetSplit =
        widget.splits.firstWhere((s) => s.id == _selectedSplitId);
    final isDifferent = _selectedSplitId != widget.activeSplitId;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.onyx,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppColors.steel, width: 1.5),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tactile Notch
              Center(
                child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.steel,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Text(
                'SWITCH TRAINING SPLIT',
                style: AppTypography.headlineSmall.copyWith(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.pureWhite,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: AppColors.platinum),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Text(
            'Select your active program to update weekly rotation & tracking.',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12.0,
              color: AppColors.platinum,
            ),
          ),

          const SizedBox(height: 16),

          // Split Options List
          for (final split in widget.splits) ...[
            InkWell(
              onTap: () => setState(() => _selectedSplitId = split.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedSplitId == split.id
                      ? AppColors.charcoal
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedSplitId == split.id
                        ? AppColors.pureWhite
                        : AppColors.steel.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    // Radio indicator
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedSplitId == split.id
                              ? AppColors.pureWhite
                              : AppColors.steel,
                          width: 2.0,
                        ),
                      ),
                      child: _selectedSplitId == split.id
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.pureWhite,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Split Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                split.name,
                                style: AppTypography.titleLarge.copyWith(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.pureWhite,
                                ),
                              ),
                              if (split.id == widget.activeSplitId) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.steel,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'ACTIVE',
                                    style: AppTypography.monoSmall.copyWith(
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.pureWhite,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${split.daysPerWeek} days/wk · ${split.totalWeeklySets} sets/wk',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.0,
                              color: AppColors.platinum,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Volume Impact Preview if changing split
          if (isDifferent) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.steel),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.pureWhite),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Shift: ${targetSplit.daysPerWeek - currentSplit.daysPerWeek >= 0 ? '+' : ''}${targetSplit.daysPerWeek - currentSplit.daysPerWeek} days/wk (${targetSplit.totalWeeklySets - currentSplit.totalWeeklySets >= 0 ? '+' : ''}${targetSplit.totalWeeklySets - currentSplit.totalWeeklySets} sets/wk volume)',
                      style: AppTypography.monoSmall.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.pureWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                widget.onSplitSelected(_selectedSplitId);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pureWhite,
                foregroundColor: AppColors.onyx,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'CONFIRM ACTIVE SPLIT',
                style: AppTypography.monoSmall.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: AppColors.onyx,
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    ),
  );
}
}

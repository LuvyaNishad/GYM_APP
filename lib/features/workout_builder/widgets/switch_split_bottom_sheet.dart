import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/persistence_feedback.dart';
import '../models/split_model.dart';

/// Root-overlay picker with a fixed, reachable default-routine action.
class SwitchSplitBottomSheet extends StatefulWidget {
  const SwitchSplitBottomSheet({
    super.key,
    required this.splits,
    required this.activeSplitId,
    required this.onSplitSelected,
  });
  final List<TrainingSplitModel> splits;
  final String activeSplitId;
  final Future<void> Function(String) onSplitSelected;
  @override
  State<SwitchSplitBottomSheet> createState() => _SwitchSplitBottomSheetState();
}

class _SwitchSplitBottomSheetState extends State<SwitchSplitBottomSheet> {
  late String _selectedSplitId = widget.activeSplitId;
  bool _saving = false;

  Future<void> _confirm() async {
    if (_saving || _selectedSplitId == widget.activeSplitId) return;
    setState(() => _saving = true);
    final success = await persistWithFeedback(
      context,
      () => widget.onSplitSelected(_selectedSplitId),
      message:
          'Could not change your default routine. Your selection is still here; try again.',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.splits.firstWhere(
      (split) => split.id == _selectedSplitId,
    );
    final custom = widget.splits.where((split) => split.isCustom);
    final templates = widget.splits.where((split) => !split.isCustom);
    return PopScope(
      canPop: !_saving,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .88,
              maxWidth: 640,
            ),
            child: Material(
              color: AppColors.onyx,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'DEFAULT ROUTINE',
                            style: AppTypography.headlineSmall.copyWith(
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: _saving
                              ? null
                              : () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Choose the routine used by Home and Start Workout. An unfinished workout stays available to resume.',
                            style: AppTypography.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Selected: ${selected.name}',
                            style: AppTypography.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          if (custom.isNotEmpty) ...[
                            _section('YOUR ROUTINES'),
                            for (final split in custom) _option(split),
                            const SizedBox(height: 12),
                          ],
                          _section('TRAINING TEMPLATES'),
                          for (final split in templates) _option(split),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed:
                              _saving ||
                                  _selectedSplitId == widget.activeSplitId
                              ? null
                              : _confirm,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: Text(
                            _saving ? 'SAVING…' : 'USE AS DEFAULT',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: AppTypography.monoSmall.copyWith(letterSpacing: 1.5),
    ),
  );

  Widget _option(TrainingSplitModel split) {
    final selected = split.id == _selectedSplitId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.charcoal : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.steel,
            ),
          ),
          selected: selected,
          enabled: !_saving,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          title: Text(split.name, style: AppTypography.bodyLarge),
          subtitle: Text(
            '${split.daysPerWeek} days per week${split.id == widget.activeSplitId ? ' · Current default' : ''}',
            style: AppTypography.bodySmall,
          ),
          trailing: Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected ? AppColors.primary : AppColors.platinum,
          ),
          onTap: _saving
              ? null
              : () => setState(() => _selectedSplitId = split.id),
        ),
      ),
    );
  }
}

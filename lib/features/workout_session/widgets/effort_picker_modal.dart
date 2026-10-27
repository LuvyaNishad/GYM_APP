import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/active_session_state.dart';
import '../../../shared/widgets/app_sheet.dart';

/// Modal bottom sheet allowing users to fine-tune effort via RIR and RPE simultaneously.
class EffortPickerModal extends StatefulWidget {
  const EffortPickerModal({
    super.key,
    required this.initialRir,
    required this.initialRpe,
    required this.onSaved,
  });

  final double initialRir;
  final double initialRpe;
  final void Function(double rir, double rpe) onSaved;

  @override
  State<EffortPickerModal> createState() => _EffortPickerModalState();
}

class _EffortPickerModalState extends State<EffortPickerModal> {
  late double _currentRir;
  late double _currentRpe;

  @override
  void initState() {
    super.initState();
    _currentRir = widget.initialRir;
    _currentRpe = widget.initialRpe;
  }

  void _updateFromRir(double rir) {
    setState(() {
      _currentRir = rir.clamp(0.0, 5.0);
      _currentRpe = rpeFromRir(_currentRir);
    });
  }

  void _nudgeRir(double delta) {
    _updateFromRir((_currentRir + delta).clamp(0.0, 5.0));
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'EFFORT SELECTOR',
      children: [
        // Big Display readout: RIR and RPE together
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.steel),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceAround,
            runSpacing: 12,
            spacing: 12,
            children: [
              Column(
                children: [
                  Text(
                    '${_currentRir.toStringAsFixed(1)} RIR',
                    style: AppTypography.monoMedium.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.pureWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Reps In Reserve',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 11.0,
                      color: AppColors.platinum,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    'RPE ${_currentRpe.toStringAsFixed(1)}',
                    style: AppTypography.monoMedium.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.pureWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Perceived Exertion',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 11.0,
                      color: AppColors.platinum,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Preset Chips Row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPresetChip(
              rir: 0.0,
              label: '0 RIR · RPE 10 (Failure)',
              isWarning: true,
            ),
            _buildPresetChip(rir: 1.0, label: '1 RIR · RPE 9 (Very Hard)'),
            _buildPresetChip(rir: 2.0, label: '2 RIR · RPE 8 (Sweet Spot)'),
            _buildPresetChip(rir: 3.0, label: '3 RIR · RPE 7 (Moderate)'),
            _buildPresetChip(rir: 4.0, label: '4+ RIR · RPE ≤6 (Warm-up)'),
          ],
        ),
        const SizedBox(height: 16),

        // Stepper Fine-tuning (0.5 increments)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepperButton(
              icon: Icons.remove,
              onPressed: () => _nudgeRir(-0.5),
              tooltip: 'Increase effort (-0.5 RIR)',
            ),
            const SizedBox(width: 20),
            Text(
              'Adjust ±0.5',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.platinum,
              ),
            ),
            const SizedBox(width: 20),
            _buildStepperButton(
              icon: Icons.add,
              onPressed: () => _nudgeRir(0.5),
              tooltip: 'Decrease effort (+0.5 RIR)',
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Confirm button
        FilledButton(
          onPressed: () {
            widget.onSaved(_currentRir, _currentRpe);
            Navigator.of(context).maybePop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'CONFIRM',
            style: AppTypography.labelSmall.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip({
    required double rir,
    required String label,
    bool isWarning = false,
  }) {
    final isSelected = (_currentRir - rir).abs() < 0.25;

    return InkWell(
      onTap: () => _updateFromRir(rir),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pureWhite : AppColors.charcoal,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.pureWhite : AppColors.steel,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.monoSmall.copyWith(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.onPrimary : AppColors.platinum,
          ),
        ),
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.steel),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.pureWhite, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

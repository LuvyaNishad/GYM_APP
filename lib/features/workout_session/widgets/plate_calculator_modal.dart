import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/warmup_plan.dart';
import '../providers/plate_preferences_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Available Olympic standard plate denominations in kilograms.
const List<double> kOlympicPlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];

/// Standard plate colors represent equipment, rather than UI accents.
Color getPlateColor(double plateKg) {
  if (plateKg >= 25.0) return const Color(0xFFDC2626); // Crimson Red
  if (plateKg >= 20.0) return const Color(0xFF2563EB); // Olympic Blue
  if (plateKg >= 15.0) return const Color(0xFFD97706); // Amber Yellow
  if (plateKg >= 10.0) return const Color(0xFF059669); // Forest Green
  if (plateKg >= 5.0) return const Color(0xFFF8FAFC); // Crisp White
  if (plateKg >= 2.5) return const Color(0xFF334155); // Dark Slate
  return const Color(0xFF64748B); // Gunmetal Steel (1.25 kg)
}

/// Choose a label with at least 4.5:1 contrast on each solid plate color.
Color getPlateLabelColor(double plateKg) {
  final luminance = getPlateColor(plateKg).computeLuminance();
  return 1.05 / (luminance + 0.05) >= 4.5 ? Colors.white : Colors.black;
}

/// Border color for each plate denomination.
Color getPlateBorderColor(double plateKg) {
  if (plateKg >= 25.0) return const Color(0xFFB91C1C);
  if (plateKg >= 20.0) return const Color(0xFF1D4ED8);
  if (plateKg >= 15.0) return const Color(0xFFB45309);
  if (plateKg >= 10.0) return const Color(0xFF047857);
  if (plateKg >= 5.0) return const Color(0xFFCBD5E1);
  if (plateKg >= 2.5) return const Color(0xFF475569);
  return const Color(0xFF94A3B8);
}

/// Calculates plate counts per barbell side given a total target weight.
Map<double, int> calculatePlatesPerSide({
  required double totalWeightKg,
  double barWeightKg = 20.0,
  List<double> availablePlates = kOlympicPlates,
}) {
  if (!totalWeightKg.isFinite ||
      !barWeightKg.isFinite ||
      barWeightKg < 0 ||
      totalWeightKg <= barWeightKg ||
      totalWeightKg > 1500) {
    return {};
  }
  final sizes =
      availablePlates
          .where((p) => p.isFinite && p >= .01 && p <= 1500)
          .map((p) => (p * 100).round())
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));
  final target = (((totalWeightKg - barWeightKg) / 2) * 100 + .000001).floor();
  // Find the closest attainable load, including non-canonical size selections
  // where greedy division can miss an exact combination (e.g. 20/15 kg).
  final counts = List<int>.filled(target + 1, target + 1);
  final chosen = List<int>.filled(target + 1, 0);
  counts[0] = 0;
  for (var weight = 1; weight <= target; weight++) {
    for (final size in sizes) {
      if (size <= weight && counts[weight - size] + 1 < counts[weight]) {
        counts[weight] = counts[weight - size] + 1;
        chosen[weight] = size;
      }
    }
  }
  var reachable = target;
  while (reachable > 0 && chosen[reachable] == 0) {
    reachable--;
  }
  final result = <double, int>{};
  while (reachable > 0) {
    final size = chosen[reachable];
    result.update(size / 100, (count) => count + 1, ifAbsent: () => 1);
    reachable -= size;
  }
  return {
    for (final size in sizes)
      if (result.containsKey(size / 100)) size / 100: result[size / 100]!,
  };
}

class PlateCalculatorModal extends ConsumerStatefulWidget {
  const PlateCalculatorModal({
    super.key,
    required this.initialTotalWeightKg,
    this.initialBarWeightKg,
    this.onWeightSelected,
    this.applyTarget,
  });
  final double initialTotalWeightKg;

  /// Explicit caller value wins for this calculator; otherwise use saved equipment.
  final double? initialBarWeightKg;
  final ValueChanged<double>? onWeightSelected;
  final String? applyTarget;
  @override
  ConsumerState<PlateCalculatorModal> createState() =>
      _PlateCalculatorModalState();
}

class _PlateCalculatorModalState extends ConsumerState<PlateCalculatorModal> {
  late double _target;
  bool _warmups = false;
  double? _barOverride;
  late final TextEditingController _targetController;
  String? _targetError;
  @override
  void initState() {
    super.initState();
    final explicitBar = widget.initialBarWeightKg;
    _barOverride =
        explicitBar != null &&
            explicitBar.isFinite &&
            explicitBar >= 0 &&
            explicitBar <= 100
        ? explicitBar
        : null;
    _target = widget.initialTotalWeightKg.isFinite
        ? widget.initialTotalWeightKg.clamp(0, 1500)
        : 20;
    _targetController = TextEditingController(text: _target.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _preferences() async {
    final prefs = ref.read(platePreferencesProvider);
    var bar = _barOverride ?? prefs.barKg;
    final available = {...prefs.plates};
    bool saving = false;
    String? error;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AppSheet(
          title: 'Your equipment',
          busy: saving,
          children: [
            Text('Bar weight', style: AppTypography.headlineSmall),
            Wrap(
              spacing: 8,
              children: [
                for (final kg in [10.0, 15.0, 20.0, 25.0])
                  ChoiceChip(
                    label: Text('${kg.toInt()} kg'),
                    selected: kg == bar,
                    onSelected: saving
                        ? null
                        : (_) => setModalState(() => bar = kg),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Available plate sizes', style: AppTypography.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Calculations assume enough pairs of each selected size.',
              style: AppTypography.bodySmall,
            ),
            for (final plate in kOlympicPlates)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('$plate kg'),
                value: available.contains(plate),
                onChanged: saving
                    ? null
                    : (v) => setModalState(() {
                        if (v == true) {
                          available.add(plate);
                        } else {
                          available.remove(plate);
                        }
                      }),
              ),
            if (error != null)
              Text(
                error!,
                style: const TextStyle(fontSize: 13, color: AppColors.warning),
              ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setModalState(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        final plates = available.toList()
                          ..sort((a, b) => b.compareTo(a));
                        await ref
                            .read(platePreferencesProvider.notifier)
                            .save(PlatePreferences(barKg: bar, plates: plates));
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          setState(() => _barOverride = null);
                        }
                      } catch (_) {
                        if (ctx.mounted) {
                          setModalState(() {
                            saving = false;
                            error = 'Could not save equipment. Try again.';
                          });
                        }
                      }
                    },
              child: Text(saving ? 'SAVING…' : 'SAVE EQUIPMENT'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(platePreferencesProvider);
    final bar = _barOverride ?? prefs.barKg;
    final breakdown = calculatePlatesPerSide(
      totalWeightKg: _target,
      barWeightKg: bar,
      availablePlates: prefs.plates,
    );
    final perSide = breakdown.entries.fold<double>(
      0,
      (v, e) => v + e.key * e.value,
    );
    final actual = bar + perSide * 2;
    final plates = [
      for (final e in breakdown.entries)
        for (var i = 0; i < e.value; i++) e.key,
    ];
    final warmups = buildWarmupPlan(actual, minimumWeight: bar);
    return AppSheet(
      title: 'Plate calculator',
      children: [
        if (widget.applyTarget != null)
          Text(
            'Apply to ${widget.applyTarget}',
            style: AppTypography.bodyMedium,
          ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _targetController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Target total weight (kg)',
            helperText: 'Includes the bar and both sides',
            errorText: _targetError,
          ),
          onChanged: (v) {
            final n = double.tryParse(v);
            setState(() {
              _targetError = n == null || !n.isFinite || n < 0 || n > 1500
                  ? 'Enter 0–1500 kg'
                  : null;
              if (_targetError == null) _target = n!;
            });
          },
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: _preferences,
          icon: const Icon(Icons.tune_rounded),
          label: Text(
            '${bar.toStringAsFixed(1)} kg bar · Equipment preferences',
          ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Plates per side')),
            ButtonSegment(value: true, label: Text('Warmup plan')),
          ],
          selected: {_warmups},
          onSelectionChanged: (s) => setState(() => _warmups = s.first),
        ),
        const SizedBox(height: 20),
        if (!_warmups)
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${perSide.toStringAsFixed(2)} kg PER SIDE',
                  style: AppTypography.monoMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 132,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.platinum,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 110,
                              color: AppColors.steel,
                            ),
                            for (final kg in plates)
                              Container(
                                width: 34,
                                height: 52 + kg * 2.8,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.charcoal,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: AppColors.platinum),
                                ),
                                alignment: Alignment.center,
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: Text(
                                    '$kg kg',
                                    style: AppTypography.monoSmall,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  breakdown.isEmpty
                      ? 'Empty bar'
                      : breakdown.entries
                            .map((e) => '${e.value} × ${e.key} kg')
                            .join('  +  '),
                  style: AppTypography.monoSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Load the same plates on each side.',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else ...[
          Text(
            'Suggested ramp: 40% / 60% / 80%. Add it from the workout’s Warmup button, then adjust for your equipment.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (final step in warmups)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(
                '${step.percentage}%',
                style: AppTypography.monoSmall,
              ),
              title: Text('${step.weightKg} kg × ${step.reps} reps'),
              subtitle: const Text('Warmup · excluded from working volume'),
            ),
        ],
        if ((actual - _target).abs() > .01)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _target < bar
                  ? 'The empty bar weighs ${bar.toStringAsFixed(1)} kg, above your target. Choose a lighter bar if needed.'
                  : 'Closest load below your target: ${actual.toStringAsFixed(2)} kg with these plates.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _targetError != null
              ? null
              : () {
                  widget.onWeightSelected?.call(actual);
                  Navigator.pop(context);
                },
          child: Text(
            widget.onWeightSelected == null
                ? 'DONE'
                : 'APPLY ${actual.toStringAsFixed(2)} KG',
          ),
        ),
      ],
    );
  }
}

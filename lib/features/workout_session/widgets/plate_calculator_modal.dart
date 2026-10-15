import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Available Olympic standard plate denominations in kilograms.
const List<double> kOlympicPlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];

/// Official Olympic & tactical color coding for standard bumper plates.
Color getPlateColor(double plateKg) {
  if (plateKg >= 25.0) return const Color(0xFFDC2626); // Crimson Red
  if (plateKg >= 20.0) return const Color(0xFF2563EB); // Olympic Blue
  if (plateKg >= 15.0) return const Color(0xFFD97706); // Amber Yellow
  if (plateKg >= 10.0) return const Color(0xFF059669); // Forest Green
  if (plateKg >= 5.0) return const Color(0xFFF8FAFC); // Crisp White
  if (plateKg >= 2.5) return const Color(0xFF334155); // Dark Slate
  return const Color(0xFF64748B); // Gunmetal Steel (1.25 kg)
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
  if (totalWeightKg <= barWeightKg) return {};

  // Round to nearest 0.01 to avoid precision floating issues
  var remainingPerSide =
      double.parse(((totalWeightKg - barWeightKg) / 2.0).toStringAsFixed(2));
  final breakdown = <double, int>{};

  for (final plate in availablePlates) {
    if (remainingPerSide >= plate) {
      final count = (remainingPerSide / plate).floor();
      if (count > 0) {
        breakdown[plate] = count;
        remainingPerSide =
            double.parse((remainingPerSide - (count * plate)).toStringAsFixed(2));
      }
    }
  }

  return breakdown;
}

/// Interactive Full Barbell Plate Calculator modal.
/// Displays the entire barbell with symmetrical weight distribution on both sides,
/// direct 1-tap plate adding/removal, and rapid weight steppers.
class PlateCalculatorModal extends StatefulWidget {
  const PlateCalculatorModal({
    super.key,
    required this.initialTotalWeightKg,
    this.initialBarWeightKg = 20.0,
    this.onWeightSelected,
  });

  final double initialTotalWeightKg;
  final double initialBarWeightKg;
  final ValueChanged<double>? onWeightSelected;

  @override
  State<PlateCalculatorModal> createState() => _PlateCalculatorModalState();
}

enum _PlateCalcTab {
  plates,
  warmupPyramid,
}

class _WarmupTier {
  const _WarmupTier({
    required this.tierNumber,
    required this.name,
    required this.percentage,
    required this.weightKg,
    required this.targetReps,
    required this.focus,
    this.isWorkingSet = false,
  });

  final int tierNumber;
  final String name;
  final String percentage;
  final double weightKg;
  final String targetReps;
  final String focus;
  final bool isWorkingSet;
}

class _PlateCalculatorModalState extends State<PlateCalculatorModal> {
  late double _totalWeightKg;
  late double _barWeightKg;
  _PlateCalcTab _selectedTab = _PlateCalcTab.plates;

  @override
  void initState() {
    super.initState();
    _totalWeightKg = widget.initialTotalWeightKg;
    _barWeightKg = widget.initialBarWeightKg;
  }

  void _adjustWeight(double delta) {
    HapticFeedback.lightImpact();
    setState(() {
      _totalWeightKg = (_totalWeightKg + delta).clamp(_barWeightKg, 500.0);
    });
  }

  void _addPlatePair(double plateKg) {
    HapticFeedback.mediumImpact();
    setState(() {
      // Adding a plate to both sides adds plateKg * 2 to total weight
      _totalWeightKg = (_totalWeightKg + (plateKg * 2.0)).clamp(_barWeightKg, 500.0);
    });
  }

  void _removePlatePair(double plateKg) {
    HapticFeedback.lightImpact();
    setState(() {
      _totalWeightKg = (_totalWeightKg - (plateKg * 2.0)).clamp(_barWeightKg, 500.0);
    });
  }

  void _clearBar() {
    HapticFeedback.mediumImpact();
    setState(() {
      _totalWeightKg = _barWeightKg;
    });
  }

  void _toggleBarWeight() {
    HapticFeedback.lightImpact();
    setState(() {
      // Toggle between 20 kg (Standard Men's) and 15 kg (Women's / Technique)
      _barWeightKg = _barWeightKg == 20.0 ? 15.0 : 20.0;
      if (_totalWeightKg < _barWeightKg) {
        _totalWeightKg = _barWeightKg;
      }
    });
  }

  Future<void> _showCustomWeightDialog() async {
    final controller = TextEditingController(
      text: _totalWeightKg % 1 == 0
          ? _totalWeightKg.toInt().toString()
          : _totalWeightKg.toStringAsFixed(1),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.onyx,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.steel),
        ),
        title: Text(
          'ENTER TARGET WEIGHT',
          style: AppTypography.headlineSmall.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: AppColors.pureWhite,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: AppTypography.monoMedium.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.pureWhite,
          ),
          decoration: InputDecoration(
            suffixText: 'KG',
            suffixStyle: AppTypography.monoSmall.copyWith(
              fontSize: 14,
              color: AppColors.platinum,
            ),
            filled: true,
            fillColor: AppColors.charcoal,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.steel),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF00E5FF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: AppTypography.monoSmall.copyWith(
                fontSize: 12,
                color: AppColors.platinum,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val >= _barWeightKg) {
                Navigator.of(ctx).pop(val);
              } else {
                Navigator.of(ctx).pop();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: Text(
              'SET WEIGHT',
              style: AppTypography.monoSmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _totalWeightKg = result.clamp(_barWeightKg, 500.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final platesPerSide = calculatePlatesPerSide(
      totalWeightKg: _totalWeightKg,
      barWeightKg: _barWeightKg,
    );

    final perSideWeight = (_totalWeightKg - _barWeightKg).clamp(0.0, 999.0) / 2.0;

    // Flatten plates into sorted list (heaviest first)
    final flatPlates = <double>[];
    for (final plate in kOlympicPlates) {
      final count = platesPerSide[plate] ?? 0;
      for (int i = 0; i < count; i++) {
        flatPlates.add(plate);
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      decoration: const BoxDecoration(
        color: AppColors.onyx,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.steel)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // ── Top Drag Handle ───────────────────────────────────────────────
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.steel,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Top Header Row ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BARBELL TOOLS',
                style: AppTypography.headlineSmall.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.pureWhite,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.platinum, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Mode Switcher Tab ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.steel),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTab = _PlateCalcTab.plates);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTab == _PlateCalcTab.plates
                            ? AppColors.steel.withValues(alpha: 0.6)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calculate_outlined,
                            size: 14,
                            color: _selectedTab == _PlateCalcTab.plates
                                ? AppColors.pureWhite
                                : AppColors.platinum,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'PLATE RACK',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: _selectedTab == _PlateCalcTab.plates
                                  ? AppColors.pureWhite
                                  : AppColors.platinum,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTab = _PlateCalcTab.warmupPyramid);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTab == _PlateCalcTab.warmupPyramid
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.20)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: _selectedTab == _PlateCalcTab.warmupPyramid
                            ? Border.all(color: const Color(0xFF00E5FF), width: 1.0)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 14,
                            color: _selectedTab == _PlateCalcTab.warmupPyramid
                                ? const Color(0xFF00E5FF)
                                : AppColors.platinum,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'WARMUP PYRAMID',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: _selectedTab == _PlateCalcTab.warmupPyramid
                                  ? const Color(0xFF00E5FF)
                                  : AppColors.platinum,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Big Total Weight & Stepper Box ────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.steel),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Quick -2.5 kg step button
                IconButton(
                  onPressed: () => _adjustWeight(-2.5),
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.platinum, size: 26),
                  tooltip: 'Decrease 2.5 kg',
                ),

                // Tap to enter custom weight
                InkWell(
                  onTap: _showCustomWeightDialog,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _totalWeightKg % 1 == 0
                                  ? _totalWeightKg.toInt().toString()
                                  : _totalWeightKg.toStringAsFixed(1),
                              style: AppTypography.monoLarge.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.pureWhite,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'KG',
                              style: AppTypography.monoSmall.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF00E5FF),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.edit, size: 14, color: AppColors.platinum),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${perSideWeight % 1 == 0 ? perSideWeight.toInt() : perSideWeight.toStringAsFixed(1)} KG EACH SIDE  •  ${_barWeightKg.toInt()} KG BAR',
                          style: AppTypography.monoSmall.copyWith(
                            fontSize: 11.0,
                            color: AppColors.platinum,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Quick +2.5 kg step button
                IconButton(
                  onPressed: () => _adjustWeight(2.5),
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00E5FF), size: 26),
                  tooltip: 'Increase 2.5 kg',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── BARBELL CONTROLS & FULL SYMMETRICAL BARBELL DISPLAY ───────────
          Row(
            children: [
              Text(
                'BARBELL SETUP',
                style: AppTypography.monoSmall.copyWith(
                  fontSize: 11.0,
                  color: AppColors.platinum,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              // Bar weight toggle chip
              OutlinedButton.icon(
                onPressed: _toggleBarWeight,
                icon: const Icon(Icons.sync, size: 12, color: AppColors.platinum),
                label: Text(
                  'BAR: ${_barWeightKg.toInt()}KG',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.platinum,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.charcoal,
                  side: const BorderSide(color: AppColors.steel),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 32),
                ),
              ),
              const SizedBox(width: 6),
              // Clear Bar chip
              OutlinedButton(
                onPressed: _clearBar,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.charcoal,
                  side: const BorderSide(color: AppColors.steel),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 32),
                ),
                child: Text(
                  'CLEAR',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.platinum,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── FULL SYMMETRICAL BARBELL DISPLAY (BOTH SIDES) ─────────────────
          Container(
            height: 104,
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.steel),
            ),
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _buildFullBarbellVisual(flatPlates),
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (_selectedTab == _PlateCalcTab.warmupPyramid) ...[
            _buildWarmupPyramidView(),
          ] else ...[
            // ── PLATES PER SIDE SUMMARY WITH 1-TAP REMOVE ─────────────────────
            Row(
              children: [
                Text(
                  'LOAD ON EACH SIDE:',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.0,
                    color: AppColors.platinum,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                if (platesPerSide.isNotEmpty)
                  Text(
                    'Tap (✕) to remove',
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 11.0,
                      color: AppColors.platinum.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (platesPerSide.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.centerLeft,
                child: Text(
                  'No plates needed — lift the empty bar (${_barWeightKg.toInt()} kg)',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.5,
                    color: AppColors.platinum,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final entry in platesPerSide.entries)
                    _buildLoadedPlateChip(entry.key, entry.value),
                ],
              ),
            const SizedBox(height: 12),

            // ── INTERACTIVE PLATE RACK (1-TAP TO ADD TO BOTH SIDES) ───────────
            Row(
              children: [
                Text(
                  'TAP TO ADD PAIR (+2×):',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.0,
                    color: AppColors.platinum,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  'Loads 1 plate per side',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.0,
                    color: AppColors.platinum.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final plate in kOlympicPlates)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _buildPlateAddButton(plate),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // ── QUICK STEPPERS (-10, -5, +5, +10) ─────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAdjustChip(label: '-10 kg', onTap: () => _adjustWeight(-10.0)),
                _buildAdjustChip(label: '-5 kg', onTap: () => _adjustWeight(-5.0)),
                _buildAdjustChip(label: '+5 kg', onTap: () => _adjustWeight(5.0)),
                _buildAdjustChip(label: '+10 kg', onTap: () => _adjustWeight(10.0)),
              ],
            ),
            const SizedBox(height: 14),

            // ── APPLY / DONE BUTTON ───────────────────────────────────────────
            FilledButton.icon(
              onPressed: () {
                widget.onWeightSelected?.call(_totalWeightKg);
                Navigator.of(context).maybePop();
              },
              icon: const Icon(Icons.check, size: 18, color: AppColors.onPrimary),
              label: Text(
                'APPLY ${_totalWeightKg % 1 == 0 ? _totalWeightKg.toInt() : _totalWeightKg.toStringAsFixed(1)} KG',
                style: AppTypography.monoSmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.onPrimary,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

  // ── Full Symmetrical Barbell Visual Builder ────────────────────────────────
  Widget _buildFullBarbellVisual(List<double> platesPerSide) {
    final hasPlates = platesPerSide.isNotEmpty;

    // Left side: plates stacked from outside inward (lightest to heaviest against collar)
    final leftPlates = platesPerSide.reversed.map((p) => _buildBarbellPlate(p)).toList();

    // Right side: plates stacked from collar outward (heaviest against collar to lightest)
    final rightPlates = platesPerSide.map((p) => _buildBarbellPlate(p)).toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Sleeve Outer Cap
        _buildSleeveCap(isLeft: true),

        // Left Plates (or empty sleeve space)
        if (!hasPlates)
          _buildEmptySleeve()
        else
          Row(mainAxisSize: MainAxisSize.min, children: leftPlates),

        // Left Collar
        _buildCollar(),

        // Center Barbell Shaft with Knurling & Weight Stamp
        _buildCenterShaft(hasPlates),

        // Right Collar
        _buildCollar(),

        // Right Plates (or empty sleeve space)
        if (!hasPlates)
          _buildEmptySleeve()
        else
          Row(mainAxisSize: MainAxisSize.min, children: rightPlates),

        // Right Sleeve Outer Cap
        _buildSleeveCap(isLeft: false),
      ],
    );
  }

  // Outer sleeve cap
  Widget _buildSleeveCap({required bool isLeft}) {
    return Container(
      width: 8,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFF64748B),
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? const Radius.circular(4) : Radius.zero,
          right: !isLeft ? const Radius.circular(4) : Radius.zero,
        ),
        border: Border.all(color: const Color(0xFF475569), width: 1),
      ),
    );
  }

  // Empty sleeve extension when no plates are on the bar
  Widget _buildEmptySleeve() {
    return Container(
      width: 44,
      height: 16,
      decoration: BoxDecoration(
        color: const Color(0xFF475569),
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.steel.withValues(alpha: 0.6)),
        ),
      ),
    );
  }

  // Barbell sleeve collar
  Widget _buildCollar() {
    return Container(
      width: 7,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFF475569), width: 1),
      ),
    );
  }

  // Center barbell shaft with knurling grooves & bar weight indicator
  Widget _buildCenterShaft(bool hasPlates) {
    return Container(
      width: hasPlates ? 110 : 130,
      height: 14,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF64748B), Color(0xFF94A3B8), Color(0xFF64748B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.steel.withValues(alpha: 0.8)),
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.charcoal.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.steel, width: 0.5),
          ),
          child: Text(
            '${_barWeightKg.toInt()}KG',
            style: const TextStyle(
              fontSize: 11.0,
              fontWeight: FontWeight.w800,
              color: AppColors.pureWhite,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // Individual plate on the visual barbell (Tappable to remove!)
  Widget _buildBarbellPlate(double plateKg) {
    // Dynamic proportional heights and widths based on Olympic specs
    double height;
    double width;

    if (plateKg >= 25.0) {
      height = 74;
      width = 13;
    } else if (plateKg >= 20.0) {
      height = 70;
      width = 13;
    } else if (plateKg >= 15.0) {
      height = 60;
      width = 12;
    } else if (plateKg >= 10.0) {
      height = 50;
      width = 11;
    } else if (plateKg >= 5.0) {
      height = 40;
      width = 10;
    } else if (plateKg >= 2.5) {
      height = 32;
      width = 9;
    } else {
      height = 26;
      width = 8;
    }

    final color = getPlateColor(plateKg);
    final borderColor = getPlateBorderColor(plateKg);
    final isWhitePlate = plateKg == 5.0;
    final plateLabel = plateKg == 1.25
        ? '1.2'
        : (plateKg % 1 == 0 ? '${plateKg.toInt()}' : plateKg.toStringAsFixed(1));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: Tooltip(
        message: 'Tap to remove $plateKg kg plate pair',
        child: InkWell(
          onTap: () => _removePlatePair(plateKg),
          borderRadius: BorderRadius.circular(2.5),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2.5),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: RotatedBox(
              quarterTurns: 3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  plateLabel,
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w900,
                    color: isWhitePlate ? const Color(0xFF0F172A) : AppColors.pureWhite,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Loaded Plate Chip with Generous 1-Tap Remove Button ───────────────────
  Widget _buildLoadedPlateChip(double plateKg, int count) {
    final color = getPlateColor(plateKg);
    final label = plateKg == 1.25
        ? '1.25'
        : (plateKg % 1 == 0 ? '${plateKg.toInt()}' : plateKg.toStringAsFixed(1));

    return Tooltip(
      message: 'Tap to remove $label kg pair',
      child: OutlinedButton(
        onPressed: () => _removePlatePair(plateKg),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.charcoal,
          side: BorderSide(color: color.withValues(alpha: 0.8), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: const Size(0, 38),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count× $label kg',
              style: AppTypography.monoSmall.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.pureWhite,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.steel.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: AppColors.pureWhite),
            ),
          ],
        ),
      ),
    );
  }

  // ── Plate Rack Add Button (1-Tap to add pair to both sides) ────────────────
  Widget _buildPlateAddButton(double plateKg) {
    final color = getPlateColor(plateKg);
    final isWhite = plateKg == 5.0;
    final label = plateKg == 1.25
        ? '1.25'
        : (plateKg % 1 == 0 ? '${plateKg.toInt()}' : plateKg.toStringAsFixed(1));

    return Tooltip(
      message: 'Add +$label kg to each side (+${(plateKg * 2).toStringAsFixed(1)} kg total)',
      child: InkWell(
        onTap: () => _addPlatePair(plateKg),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '+',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isWhite ? const Color(0xFF0F172A) : AppColors.pureWhite,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTypography.monoSmall.copyWith(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.pureWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Quick Weight Step Chip ─────────────────────────────────────────────────
  Widget _buildAdjustChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minWidth: 72, minHeight: 38),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.steel),
        ),
        child: Text(
          label,
          style: AppTypography.monoSmall.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.pureWhite,
          ),
        ),
      ),
    );
  }

  // ── Multi-Stage Barbell Warmup Pyramid Builder ─────────────────────────────
  Widget _buildWarmupPyramidView() {
    final stages = [
      _WarmupTier(
        tierNumber: 1,
        name: 'Empty Bar Warmup',
        percentage: 'BAR',
        weightKg: _barWeightKg,
        targetReps: '10 Reps',
        focus: 'Mobility & joint lubrication',
      ),
      _WarmupTier(
        tierNumber: 2,
        name: 'Initial Ramp',
        percentage: '50%',
        weightKg: (((_totalWeightKg * 0.50) / 2.5).round() * 2.5).clamp(_barWeightKg, 500.0),
        targetReps: '5 Reps',
        focus: 'Establish bar path & cadence',
      ),
      _WarmupTier(
        tierNumber: 3,
        name: 'Working Potentiation',
        percentage: '70%',
        weightKg: (((_totalWeightKg * 0.70) / 2.5).round() * 2.5).clamp(_barWeightKg, 500.0),
        targetReps: '3 Reps',
        focus: 'Acceleration & abdominal bracing',
      ),
      _WarmupTier(
        tierNumber: 4,
        name: 'Neural Primer',
        percentage: '85%',
        weightKg: (((_totalWeightKg * 0.85) / 2.5).round() * 2.5).clamp(_barWeightKg, 500.0),
        targetReps: '1 Rep',
        focus: 'CNS potentiator (zero fatigue)',
      ),
      _WarmupTier(
        tierNumber: 5,
        name: 'Working Set',
        percentage: '100%',
        weightKg: _totalWeightKg,
        targetReps: 'Target Reps',
        focus: 'Target performance load',
        isWorkingSet: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROGRESSIVE PYRAMID TIERS',
              style: AppTypography.monoSmall.copyWith(
                fontSize: 11.0,
                color: AppColors.platinum,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Tap LOAD to set weight',
              style: AppTypography.monoSmall.copyWith(
                fontSize: 11.0,
                color: AppColors.platinum.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final tier in stages) ...[
          _buildWarmupTierCard(tier),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildWarmupTierCard(_WarmupTier tier) {
    final plates = calculatePlatesPerSide(
      totalWeightKg: tier.weightKg,
      barWeightKg: _barWeightKg,
    );
    final isCurrentWeight = (_totalWeightKg - tier.weightKg).abs() < 0.1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tier.isWorkingSet
            ? const Color(0xFF00E5FF).withValues(alpha: 0.08)
            : AppColors.charcoal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tier.isWorkingSet
              ? const Color(0xFF00E5FF)
              : (isCurrentWeight ? AppColors.pureWhite : AppColors.steel),
          width: tier.isWorkingSet || isCurrentWeight ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tier percentage pill
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: tier.isWorkingSet
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
                  : AppColors.onyx,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: tier.isWorkingSet
                    ? const Color(0xFF00E5FF)
                    : AppColors.steel,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tier.percentage,
                  style: TextStyle(
                    fontFamily: AppTypography.fontMono,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w900,
                    color: tier.isWorkingSet
                        ? const Color(0xFF00E5FF)
                        : AppColors.pureWhite,
                  ),
                ),
                Text(
                  'SET ${tier.tierNumber}',
                  style: TextStyle(
                    fontFamily: AppTypography.fontMono,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.platinum.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Details: Name, Load, Reps, Plates
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${tier.weightKg % 1 == 0 ? tier.weightKg.toInt() : tier.weightKg.toStringAsFixed(1)} KG',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontMono,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w900,
                        color: AppColors.pureWhite,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${tier.targetReps}',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontMono,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00E5FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tier.focus,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontBody,
                    fontSize: 11.0,
                    color: AppColors.platinum,
                  ),
                ),
                const SizedBox(height: 6),

                // Plates required per side
                if (plates.isEmpty)
                  Text(
                    'Empty bar (${_barWeightKg.toInt()} kg)',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontMono,
                      fontSize: 11.0,
                      color: AppColors.platinum,
                    ),
                  )
                else
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final entry in plates.entries)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: getPlateColor(entry.key),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: getPlateBorderColor(entry.key), width: 1.0),
                          ),
                          child: Text(
                            '${entry.value}×${entry.key % 1 == 0 ? entry.key.toInt() : entry.key}k',
                            style: TextStyle(
                              fontFamily: AppTypography.fontMono,
                              fontSize: 11.0,
                              fontWeight: FontWeight.w900,
                              color: entry.key == 5.0 ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Actions: PREVIEW on bar & LOAD into set
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onWeightSelected?.call(tier.weightKg);
                  Navigator.of(context).maybePop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: tier.isWorkingSet
                      ? const Color(0xFF00E5FF)
                      : AppColors.pureWhite,
                  foregroundColor: AppColors.onyx,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(60, 34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'LOAD',
                  style: TextStyle(
                    fontFamily: AppTypography.fontMono,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.onyx,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _totalWeightKg = tier.weightKg);
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    isCurrentWeight ? 'VIEWING' : 'PREVIEW',
                    style: TextStyle(
                      fontFamily: AppTypography.fontMono,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: isCurrentWeight
                          ? const Color(0xFF00E5FF)
                          : AppColors.platinum,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

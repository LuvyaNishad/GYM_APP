import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/exercise_library_item.dart';
import '../providers/exercise_library_provider.dart';

/// Screen allowing the user to create a personalized custom exercise definition.
class CustomExerciseCreatorScreen extends ConsumerStatefulWidget {
  const CustomExerciseCreatorScreen({super.key});

  @override
  ConsumerState<CustomExerciseCreatorScreen> createState() =>
      _CustomExerciseCreatorScreenState();
}

class _CustomExerciseCreatorScreenState
    extends ConsumerState<CustomExerciseCreatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _primaryMusclesController = TextEditingController();
  final _cuesController = TextEditingController();

  String _category = 'Chest';
  String _equipment = 'barbell';
  String _exerciseType = 'compound';
  int _restSeconds = 90;

  static const List<String> _categories = [
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Legs',
    'Core',
    'Full Body',
    'Mobility',
  ];

  static const List<String> _equipmentOptions = [
    'barbell',
    'dumbbell',
    'cable',
    'machine',
    'bodyweight',
    'band',
    'kettlebell',
    'other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _primaryMusclesController.dispose();
    _cuesController.dispose();
    super.dispose();
  }

  void _saveExercise() {
    if (!_formKey.currentState!.validate()) return;

    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final name = _nameController.text.trim();
    final primaryMuscles = _primaryMusclesController.text
        .split(RegExp(r'[,;]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final cues = _cuesController.text.trim();

    final customItem = ExerciseLibraryItem(
      id: id,
      name: name,
      category: _category,
      description: 'Custom exercise created by user.',
      primaryMuscles: primaryMuscles.isNotEmpty ? primaryMuscles : [_category],
      equipment: [_equipment],
      primaryEquipment: _equipment,
      movementPattern: 'general',
      exerciseType: _exerciseType,
      difficulty: 'intermediate',
      tags: ['custom', _category.toLowerCase(), _equipment],
      instructions: cues.isNotEmpty ? [cues] : ['Execute movement with controlled form.'],
      coachingNotes: cues,
      defaultRestSeconds: _restSeconds,
      isCustom: true,
    );

    ref.read(exerciseLibraryProvider.notifier).addCustomExercise(customItem);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF141722),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.primary, width: 1),
        ),
        content: Text(
          'Custom exercise "$name" created successfully!',
          style: AppTypography.bodySmall.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'CREATE CUSTOM EXERCISE',
          style: AppTypography.headlineMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // ── Exercise Name Input ───────────────────────────────────
              _buildFieldLabel('EXERCISE NAME *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                decoration: _inputDecoration(hintText: 'e.g. Arsenal Strength Hack Squat'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter an exercise name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // ── Muscle Category Selector ──────────────────────────────
              _buildFieldLabel('TARGET MUSCLE GROUP'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _category == cat;
                  return InkWell(
                    onTap: () => setState(() => _category = cat),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.18)
                            : const Color(0xFF141722),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.10),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 12.0,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // ── Primary Muscles Text Input ────────────────────────────
              _buildFieldLabel('PRIMARY MUSCLES (COMMA SEPARATED)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _primaryMusclesController,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                decoration: _inputDecoration(hintText: 'e.g. Quadriceps, Gluteus Maximus'),
              ),
              const SizedBox(height: 18),

              // ── Equipment Dropdown ────────────────────────────────────
              _buildFieldLabel('PRIMARY EQUIPMENT'),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141722),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _equipment,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF161A23),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                    items: _equipmentOptions.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt,
                        child: Text(
                          opt.toUpperCase(),
                          style: AppTypography.monoSmall.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _equipment = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── Exercise Type (Compound / Isolation) ──────────────────
              _buildFieldLabel('MOVEMENT TYPE'),
              const SizedBox(height: 6),
              Row(
                children: ['compound', 'isolation'].map((type) {
                  final isSelected = _exerciseType == type;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => setState(() => _exerciseType = type),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.18)
                                : const Color(0xFF141722),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.10),
                              width: 1.0,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              type.toUpperCase(),
                              style: AppTypography.monoSmall.copyWith(
                                fontSize: 12.0,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // ── Default Rest Interval ─────────────────────────────────
              _buildFieldLabel('DEFAULT REST INTERVAL'),
              const SizedBox(height: 6),
              Row(
                children: [60, 90, 120, 180].map((secs) {
                  final isSelected = _restSeconds == secs;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () => setState(() => _restSeconds = secs),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.18)
                                : const Color(0xFF141722),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.10),
                              width: 1.0,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${secs}s',
                              style: AppTypography.monoSmall.copyWith(
                                fontSize: 12.0,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // ── Form & Coaching Cues ──────────────────────────────────
              _buildFieldLabel('COACHING CUES / FORM NOTES'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _cuesController,
                maxLines: 3,
                style: AppTypography.bodySmall.copyWith(color: Colors.white, fontSize: 13),
                decoration: _inputDecoration(hintText: 'e.g. Feet shoulder width, drive through heels, full depth.'),
              ),
              const SizedBox(height: 30),

              // ── Save CTA ──────────────────────────────────────────────
              FilledButton(
                onPressed: _saveExercise,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'SAVE CUSTOM EXERCISE',
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTypography.labelSmall.copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: const Color(0xFF94A3B8),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTypography.bodySmall.copyWith(
        fontSize: 12.5,
        color: const Color(0xFF64748B),
      ),
      filled: true,
      fillColor: const Color(0xFF141722),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

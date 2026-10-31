/// Edit Profile & Identity Bottom Sheet for LEON.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/account_profile_model.dart';
import '../providers/profile_provider.dart';
import '../../workout_builder/providers/splits_provider.dart';
import '../../workout_builder/models/programme_configuration.dart';
import '../../../shared/widgets/persistence_feedback.dart';

/// Shows the Edit Profile modal sheet.
void showEditProfileSheet(BuildContext context, AccountProfile profile) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _EditProfileSheet(profile: profile),
  );
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.profile});

  final AccountProfile profile;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late String _selectedSplit;
  late String _selectedLevel;

  static const _levels = ['Not set', 'Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _emailController = TextEditingController(text: widget.profile.email);
    _selectedSplit = resolveSplitId(widget.profile.preferredSplit);
    _selectedLevel =
        _levels
            .where(
              (level) =>
                  level.toLowerCase() ==
                  widget.profile.experienceLevel.toLowerCase(),
            )
            .firstOrNull ??
        'Not set';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _isSaving = false;

  Future<void> _save() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    final success = await persistWithFeedback(
      context,
      () => ref
          .read(accountProfileProvider.notifier)
          .updateProfile(
            displayName: name,
            email: email,
            preferredSplit: _selectedSplit,
            experienceLevel: _selectedLevel,
          ),
      message:
          'Could not save your profile. Your edits are still here. Please try again.',
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!success) return;

    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    messenger.showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.charcoal,
        content: Text(
          'Profile updated successfully!',
          style: TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 13.0,
            color: AppColors.pureWhite,
          ),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final available = ref.watch(splitsProvider).splits;
    final splitNames = {for (final s in available) s.id: s.name};
    final availableSplits = [
      ...splitNames.keys,
      if (!splitNames.containsKey(_selectedSplit)) _selectedSplit,
    ];
    return PersistenceForm(
      pending: _isSaving,
      child: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontFamily: AppTypography.fontDisplay,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pureWhite,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.platinum,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Display Name
              const Text(
                'FULL NAME',
                style: TextStyle(
                  fontFamily: AppTypography.fontDisplay,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: const TextStyle(
                  fontFamily: AppTypography.fontBody,
                  fontSize: 14.5,
                  color: AppColors.pureWhite,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.charcoal,
                  hintText: 'Enter name',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.steel.withValues(alpha: 0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.steel.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Email
              const Text(
                'EMAIL ADDRESS',
                style: TextStyle(
                  fontFamily: AppTypography.fontDisplay,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                style: const TextStyle(
                  fontFamily: AppTypography.fontBody,
                  fontSize: 14.5,
                  color: AppColors.pureWhite,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.charcoal,
                  hintText: 'Enter email',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.steel.withValues(alpha: 0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.steel.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Training Split selector
              const Text(
                'PREFERRED TRAINING SPLIT',
                style: TextStyle(
                  fontFamily: AppTypography.fontDisplay,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.steel.withValues(alpha: 0.5),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSplit,
                    dropdownColor: AppColors.charcoal,
                    isExpanded: true,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 14,
                      color: AppColors.pureWhite,
                    ),
                    items: availableSplits
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(splitNames[s] ?? 'Saved split ($s)'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSplit = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Experience level
              const Text(
                'EXPERIENCE LEVEL',
                style: TextStyle(
                  fontFamily: AppTypography.fontDisplay,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: _levels.map((lvl) {
                  final isSel = lvl == _selectedLevel;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () => setState(() => _selectedLevel = lvl),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.charcoal,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel
                                  ? AppColors.primary
                                  : AppColors.steel.withValues(alpha: 0.5),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            lvl,
                            style: TextStyle(
                              fontFamily: AppTypography.fontBody,
                              fontSize: 12.0,
                              fontWeight: isSel
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSel
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pureWhite,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontFamily: AppTypography.fontDisplay,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
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

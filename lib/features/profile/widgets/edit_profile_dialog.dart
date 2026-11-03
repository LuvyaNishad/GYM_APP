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
import '../../../shared/widgets/app_sheet.dart';
import 'account_section.dart';

/// Shows the Edit Profile modal sheet.
void showEditProfileSheet(BuildContext context, AccountProfile profile) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    enableDrag: false,
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
      child: AppSheet(
        title: 'Edit Profile',
        busy: _isSaving,
        children: [
          TextField(
            controller: _nameController,
            style: AccountType.row,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Full name',
              hintText: 'Enter name',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            style: AccountType.row,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Email address',
              hintText: 'Optional',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedSplit,
            isExpanded: true,
            isDense: false,
            itemHeight: null,
            style: AccountType.row,
            decoration: const InputDecoration(labelText: 'Training split'),
            items: [
              for (final split in availableSplits)
                DropdownMenuItem(
                  value: split,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(splitNames[split] ?? 'Saved split ($split)'),
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _selectedSplit = value);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedLevel,
            isExpanded: true,
            isDense: false,
            itemHeight: null,
            style: AccountType.row,
            decoration: const InputDecoration(labelText: 'Experience level'),
            items: [
              for (final level in _levels)
                DropdownMenuItem(
                  value: level,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(level),
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _selectedLevel = value);
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}

/// Edit Profile & Identity Bottom Sheet for AEON.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final _formKey = GlobalKey<FormState>();
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
        widget.profile.experienceLevel;
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

    if (!(_formKey.currentState?.validate() ?? false)) {
      showAppFeedback(
        context,
        'Check your name and contact email before saving.',
      );
      return;
    }

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
    showAppFeedback(context, 'Profile saved.', isError: false);
    Navigator.of(context).pop();
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
      child: Form(
        key: _formKey,
        child: AppSheet(
          title: 'Edit Profile',
          busy: _isSaving,
          children: [
            TextFormField(
              controller: _nameController,
              style: AccountType.row,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  value?.trim().isEmpty != false ? 'Enter your name.' : null,
              decoration: const InputDecoration(
                labelText: 'Full name',
                hintText: 'Enter name',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              style: AccountType.row,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              validator: (value) {
                final email = value?.trim() ?? '';
                return email.isEmpty ||
                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
                    ? null
                    : 'Enter a valid email or leave it empty.';
              },
              decoration: const InputDecoration(
                labelText: 'Contact email',
                hintText: 'Optional',
                helperText: 'Saved with your fitness profile.',
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
                for (final level in [
                  ..._levels,
                  if (!_levels.contains(_selectedLevel)) _selectedLevel,
                ])
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
      ),
    );
  }
}

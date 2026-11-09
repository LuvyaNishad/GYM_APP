import '../../../services/pedometer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/persistence_feedback.dart';
import '../../../services/backup_service.dart';
import '../../../services/export_file_service.dart';
import '../../../services/hive_service.dart';
import '../../../models/workout_model.dart';
import '../models/account_profile_model.dart';
import '../services/training_report_data.dart';

void showExportDataSheet(BuildContext context, [AccountProfile? profile]) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: AppColors.surface,
    builder: (_) => const _ExportDataSheet(),
  );
}

class _ExportDataSheet extends ConsumerStatefulWidget {
  const _ExportDataSheet();
  @override
  ConsumerState<_ExportDataSheet> createState() => _ExportDataSheetState();
}

class _ExportDataSheetState extends ConsumerState<_ExportDataSheet> {
  bool busy = false;
  String? message;
  BackupPreview? preview;
  RestoreMode mode = RestoreMode.keepExisting;
  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(
          () => message =
              'Could not complete this action. Try again or choose a valid AEON backup.',
        );
        showAppFeedback(context, message!);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> export(bool share, {bool csv = false}) => run(() async {
    final files = ref.read(exportFileServiceProvider);
    final bytes = csv
        ? TrainingReportData.workoutsCsv(
            (((await ref
                            .read(hiveServiceProvider)
                            .flushedSnapshot())['documents']
                        as Map)['workouts']
                    as Map)
                .values
                .map(
                  (j) => WorkoutModel.fromJson(
                    Map<String, dynamic>.from(j as Map),
                  ),
                )
                .toList(),
          )
        : await ref.read(backupServiceProvider).export();
    final name =
        'AEON-${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-')}.${csv ? 'csv' : 'json'}';
    final mime = csv ? 'text/csv' : 'application/json';
    final result = share
        ? (await files.share(name, mime, bytes)
              ? 'Share sheet opened.'
              : 'Sharing cancelled.')
        : ((await files.save(name, mime, bytes)) == null
              ? 'Save cancelled.'
              : 'File saved to your selected destination.');
    if (mounted) {
      setState(() => message = result);
      showAppFeedback(context, result, isError: false);
    }
  });
  Future<void> pick() => run(() async {
    final bytes = await ref.read(exportFileServiceProvider).pickBackup();
    if (bytes == null) {
      if (mounted) {
        showAppFeedback(context, 'File selection cancelled.', isError: false);
      }
      return;
    }
    final value = await ref.read(backupServiceProvider).preview(bytes);
    if (mounted) {
      setState(() {
        preview = value;
        mode = RestoreMode.keepExisting;
      });
    }
  });
  Future<void> restore() async {
    if (busy || preview == null) return;
    if (mode == RestoreMode.replaceAll) {
      final confirmed = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Replace saved data?'),
          content: const Text(
            'This replaces your current workouts, routines, measurements and backed-up preferences with the selected backup.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Replace data'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await run(() async {
      await ref.read(backupServiceProvider).restore(preview!, mode);
      // Rebuild every storage-dependent provider from the restored store.
      ref.invalidate(hiveServiceProvider);
      ref.invalidate(pedometerServiceProvider);
      if (mounted) {
        setState(() {
          preview = null;
          message = 'Backup restored on this device.';
        });
        showAppFeedback(context, message!, isError: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .86,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'BACKUP & EXPORT',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text(
                'Backups include workouts, routines, pauses, measurements, habits, steps and preferences. They contain personal data; choose where to save or share them.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Active workout drafts, sign-in credentials and phone sensor baselines stay on this installation.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: busy ? null : () => export(false),
                child: const Text('Save backup JSON'),
              ),
              OutlinedButton(
                onPressed: busy ? null : () => export(true),
                child: const Text('Share backup JSON'),
              ),
              OutlinedButton(
                onPressed: busy ? null : () => export(false, csv: true),
                child: const Text('Save logged sets CSV'),
              ),
              OutlinedButton(
                onPressed: busy ? null : pick,
                child: const Text('Choose backup to restore'),
              ),
              if (preview != null) ...[
                const SizedBox(height: 16),
                GlassCard(
                  blur: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'RESTORE PREVIEW',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text('Created ${preview!.createdAt.toLocal()}'),
                      for (final change in preview!.changes)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(change),
                        ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<RestoreMode>(
                        key: ValueKey(preview),
                        isExpanded: true,
                        isDense: false,
                        itemHeight: null,
                        initialValue: mode,
                        decoration: const InputDecoration(
                          labelText: 'Restore behavior',
                        ),
                        onChanged: busy
                            ? null
                            : (v) => setState(() => mode = v!),
                        items: const [
                          DropdownMenuItem(
                            value: RestoreMode.keepExisting,
                            child: Text('Merge: keep device conflicts'),
                          ),
                          DropdownMenuItem(
                            value: RestoreMode.useBackup,
                            child: Text('Merge: use backup conflicts'),
                          ),
                          DropdownMenuItem(
                            value: RestoreMode.replaceAll,
                            child: Text('Replace all backed-up data'),
                          ),
                        ],
                      ),
                      Text(switch (mode) {
                        RestoreMode.keepExisting =>
                          'Adds missing IDs. Identical records are not duplicated. Existing records and preferences win conflicts.',
                        RestoreMode.useBackup =>
                          'Adds missing IDs and replaces conflicting IDs/preferences from the backup. Other device records remain.',
                        RestoreMode.replaceAll =>
                          'Removes all current workouts, routines, measurements, habits and backed-up preferences and replaces them with this backup.',
                      }),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: busy ? null : restore,
                        child: Text(
                          mode == RestoreMode.replaceAll
                              ? 'Replace data with this backup'
                              : 'Restore with selected merge',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(message!),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

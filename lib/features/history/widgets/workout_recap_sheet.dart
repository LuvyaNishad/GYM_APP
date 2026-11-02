import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/workout_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/measurement_units.dart';
import '../../../services/export_file_service.dart';
import '../services/workout_recap_service.dart';

void showWorkoutRecapSheet(BuildContext context, WorkoutModel workout) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _RecapSheet(workout),
    );

class _RecapSheet extends ConsumerStatefulWidget {
  const _RecapSheet(this.workout);
  final WorkoutModel workout;
  @override
  ConsumerState<_RecapSheet> createState() => _RecapSheetState();
}

class _RecapSheetState extends ConsumerState<_RecapSheet> {
  bool details = false, busy = false;
  String? message;
  late Future<Uint8List> preview;
  @override
  void initState() {
    super.initState();
    generate();
  }

  void generate() {
    preview = WorkoutRecapService.png(
      widget.workout,
      units: ref.read(measurementUnitsProvider),
      includeDetails: details,
    );
  }

  Future<void> export(bool share) async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final bytes = await preview;
      final files = ref.read(exportFileServiceProvider);
      final result = share
          ? (await files.share('AEON-workout.png', 'image/png', bytes)
                ? 'Share sheet opened.'
                : 'Sharing cancelled.')
          : (await files.save('AEON-workout.png', 'image/png', bytes) == null
                ? 'Save cancelled.'
                : 'Image saved.');
      if (mounted) setState(() => message = result);
    } catch (e) {
      if (mounted) setState(() => message = 'Could not export image: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .86,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'WORKOUT RECAP',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                letterSpacing: 1.5,
              ),
            ),
            SwitchListTile(
              title: const Text('Include workout title, date and exercises'),
              subtitle: const Text(
                'Off by default. Profile name, notes and body measurements are always omitted.',
              ),
              value: details,
              onChanged: busy
                  ? null
                  : (v) => setState(() {
                      details = v;
                      generate();
                    }),
            ),
            FutureBuilder<Uint8List>(
              future: preview,
              builder: (context, snapshot) => snapshot.hasData
                  ? SizedBox(height: 360, child: Image.memory(snapshot.data!))
                  : Text(
                      snapshot.hasError
                          ? 'Could not create image: ${snapshot.error}'
                          : 'Creating preview…',
                    ),
            ),
            FilledButton(
              onPressed: busy ? null : () => export(false),
              child: const Text('Save 1080 × 1920 PNG'),
            ),
            OutlinedButton(
              onPressed: busy ? null : () => export(true),
              child: const Text('Share image'),
            ),
            if (message != null) Text(message!),
          ],
        ),
      ),
    ),
  );
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/health_sync_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/health_import.dart';
import '../providers/health_tracking_provider.dart';

const healthPrivacyExplanation =
    'Choose which metrics to read from your phone’s health platform. '
    'Health data stays on this device, is excluded from backups and is never written back. '
    'Manual sleep and active-calorie entries take precedence. Steps and calories from different sources are never added. '
    'Turning an import off removes its values from the app; revoke system access in your health settings. '
    'Sleep covers yesterday noon to today noon (or now). Heart rate is the latest sample today, not a resting baseline. '
    'Apple Health keeps read permissions private: an empty result can mean no data or no access.';

class HealthConnectionCard extends ConsumerStatefulWidget {
  const HealthConnectionCard({super.key});
  @override
  ConsumerState<HealthConnectionCard> createState() =>
      _HealthConnectionCardState();
}

class _HealthConnectionCardState extends ConsumerState<HealthConnectionCard> {
  bool _busy = false;
  String? _error;
  Future<void> _perform(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not complete the action. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(healthPreferencesProvider);
    final async = ref.watch(healthImportProvider);
    final imported = ref.watch(currentHealthImportProvider);
    final availability = async.value?.availability;
    return GlassCard(
      blur: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PHONE HEALTH DATA',
            style: AppTypography.headlineSmall.copyWith(letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            async.isLoading
                ? 'Checking availability and read access…'
                : switch (availability) {
                    HealthAvailability.ready =>
                      'Choose imports, then allow read access.',
                    HealthAvailability.installRequired =>
                      'Install or update Health Connect to import data.',
                    HealthAvailability.error =>
                      'Could not check your health platform. Refresh to retry.',
                    _ =>
                      'Health imports are unavailable on this device. Phone steps and manual logs still work.',
                  },
            style: AppTypography.bodySmall,
          ),
          for (final metric in HealthMetric.values) ...[
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(metric.label, style: AppTypography.bodyMedium),
              subtitle: Text(
                async.isLoading && selected.contains(metric)
                    ? 'Checking read access…'
                    : imported?.reading(metric).statusLabel ?? 'Import off',
                style: AppTypography.bodySmall,
              ),
              value: selected.contains(metric),
              onChanged: _busy
                  ? null
                  : (enabled) => _perform(
                      () => ref
                          .read(healthPreferencesProvider.notifier)
                          .select(metric, enabled),
                    ),
            ),
            if (imported?.reading(metric).value != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${imported!.reading(metric).platform} · ${imported.reading(metric).sources.join(', ')}\n'
                  '${imported.reading(metric).method ?? ''}'
                  '${imported.reading(metric).sampleAt == null ? '' : '\nSample: ${MaterialLocalizations.of(context).formatMediumDate(imported.reading(metric).sampleAt!)} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(imported.reading(metric).sampleAt!))}'}',
                  style: AppTypography.bodySmall,
                ),
              ),
          ],
          if (availability == HealthAvailability.ready)
            FilledButton(
              onPressed: _busy || selected.isEmpty || async.isLoading
                  ? null
                  : () => _perform(
                      () => ref.read(healthImportProvider.notifier).authorize(),
                    ),
              child: const Text('ALLOW SELECTED READ ACCESS'),
            ),
          if (availability == HealthAvailability.ready ||
              availability == HealthAvailability.installRequired)
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _perform(
                      () => ref.read(healthSyncServiceProvider).openSettings(),
                    ),
              child: Text(
                availability == HealthAvailability.installRequired
                    ? 'INSTALL HEALTH CONNECT'
                    : Platform.isIOS
                    ? 'OPEN APPLE HEALTH'
                    : 'HEALTH CONNECT SETTINGS',
              ),
            ),
          Text(healthPrivacyExplanation, style: AppTypography.bodySmall),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

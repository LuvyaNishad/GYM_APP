import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Local storage is available independently of connectivity. Cloud sync is not configured.
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({
    super.key,
    this.isOnline = false,
    this.showLabel = false,
  });
  final bool isOnline, showLabel;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Local storage',
    child: InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Local storage'),
          content: const Text(
            'Saved records stay on this device. Cloud sync is unavailable. Each save reports any storage error; a device backup is still needed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(),
              child: const Text('CLOSE'),
            ),
          ],
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.phone_android_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            if (showLabel)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text('LOCAL', style: AppTypography.dataLabel),
              ),
          ],
        ),
      ),
    ),
  );
}

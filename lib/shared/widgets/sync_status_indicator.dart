import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../services/sync_service.dart';

/// Truthful cloud synchronization indicator.
/// Reflects real-time state: idle, syncing, synced, offline, or error.
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({
    super.key,
    this.isOnline = false,
    this.showLabel = false,
  });

  final bool isOnline;
  final bool showLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncServiceProvider);

    IconData icon;
    Color color;
    String label;
    String tooltip;

    switch (syncState.status) {
      case SyncStatus.syncing:
        icon = Icons.sync_rounded;
        color = AppColors.activeCyan;
        label = 'SYNCING';
        tooltip = 'Syncing data with cloud...';
        break;
      case SyncStatus.synced:
        icon = Icons.cloud_done_rounded;
        color = AppColors.gymGreen;
        label = 'SYNCED';
        tooltip = syncState.lastSyncedAt != null
            ? 'Synced at ${syncState.lastSyncedAt!.hour.toString().padLeft(2, '0')}:${syncState.lastSyncedAt!.minute.toString().padLeft(2, '0')}'
            : 'Synced with cloud';
        break;
      case SyncStatus.offline:
        icon = Icons.cloud_off_rounded;
        color = AppColors.textSecondary;
        label = 'OFFLINE';
        tooltip = 'Offline — saved locally on device';
        break;
      case SyncStatus.error:
        icon = Icons.sync_problem_rounded;
        color = AppColors.gymRed;
        label = 'RETRY';
        tooltip = syncState.errorMessage ?? 'Sync error — tap to retry';
        break;
      case SyncStatus.idle:
        icon = Icons.cloud_queue_rounded;
        color = AppColors.textSecondary;
        label = 'READY';
        tooltip = 'Tap to sync with cloud';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => ref.read(syncServiceProvider.notifier).syncAll(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (syncState.status == SyncStatus.syncing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              else
                Icon(icon, color: color, size: 20),
              if (showLabel) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.dataLabel.copyWith(
                    color: color,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

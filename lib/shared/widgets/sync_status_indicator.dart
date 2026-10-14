/// Offline-First Synchronization Status Indicator for LEON.
///
/// Communicates zero data loss and local data persistence confidence to users.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({
    super.key,
    this.isOnline = true,
    this.showLabel = false,
  });

  final bool isOnline;
  final bool showLabel;

  void _showSyncInfoDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.onyx,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.steel),
        ),
        title: Row(
          children: [
            Icon(
              isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              color: isOnline ? const Color(0xFF00E5FF) : const Color(0xFFFFB300),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'OFFLINE-FIRST DATA SAFETY',
              style: AppTypography.headlineSmall.copyWith(
                fontSize: 14.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.pureWhite,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.steel.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline
                          ? const Color(0xFF00E5FF)
                          : const Color(0xFFFFB300),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isOnline
                          ? 'SAVED LOCALLY & SYNCED'
                          : 'SAVED LOCALLY (OFFLINE)',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isOnline
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFFFFB300),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'All your workout logs, PR records, and personal routines are saved locally first via Hive storage.\n\nYou never lose data when training in basements or without internet. Changes sync automatically when connected.',
              style: TextStyle(
                fontFamily: AppTypography.fontBody,
                fontSize: 12.0,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'UNDERSTOOD',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFF00E5FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor =
        isOnline ? const Color(0xFF00E5FF) : const Color(0xFFFFB300);

    return GestureDetector(
      onTap: () => _showSyncInfoDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor,
              ),
            ),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                isOnline ? 'SAVED' : 'OFFLINE',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11.0,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

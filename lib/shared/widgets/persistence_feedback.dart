import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class PersistenceForm extends StatelessWidget {
  const PersistenceForm({
    super.key,
    required this.pending,
    required this.child,
  });
  final bool pending;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !pending,
    child: ExcludeFocus(
      excluding: pending,
      child: AbsorbPointer(absorbing: pending, child: child),
    ),
  );
}

/// Providers propagate errors. A failed UI action keeps its input available.
Future<bool> persistWithFeedback(
  BuildContext context,
  Future<void> Function() action, {
  String message = 'Could not save changes. Please try again.',
}) async {
  try {
    await action();
    return true;
  } catch (_) {
    if (context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.charcoal,
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 13,
              color: AppColors.pureWhite,
            ),
          ),
        ),
      );
    }
    return false;
  }
}

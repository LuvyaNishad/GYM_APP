import 'dart:async';
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

final _feedbackDismissals = Expando<VoidCallback>();

/// Root-overlay feedback stays above navigation, sheets and the keyboard.
void showAppFeedback(
  BuildContext context,
  String message, {
  bool isError = true,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _feedbackDismissals[overlay]?.call();
  late final OverlayEntry entry;
  var closed = false;
  void dismiss() {
    if (closed) return;
    closed = true;
    _feedbackDismissals[overlay] = null;
    entry.remove();
    entry.dispose();
  }

  entry = OverlayEntry(
    builder: (_) => _TopFeedback(
      message: message,
      isError: isError,
      onDismiss: dismiss,
      onDisposed: () {
        if (!closed) {
          closed = true;
          _feedbackDismissals[overlay] = null;
        }
      },
    ),
  );
  _feedbackDismissals[overlay] = dismiss;
  overlay.insert(entry);
}

class _TopFeedback extends StatefulWidget {
  const _TopFeedback({
    required this.message,
    required this.isError,
    required this.onDismiss,
    required this.onDisposed,
  });
  final String message;
  final bool isError;
  final VoidCallback onDismiss, onDisposed;
  @override
  State<_TopFeedback> createState() => _TopFeedbackState();
}

class _TopFeedbackState extends State<_TopFeedback> {
  Timer? _timer;
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!MediaQuery.accessibleNavigationOf(context)) {
      _timer = Timer(const Duration(seconds: 8), widget.onDismiss);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.onDisposed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        minimum: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: reduced ? 1 : 0, end: 1),
              duration: Duration(milliseconds: reduced ? 0 : 180),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, -12 * (1 - value)),
                  child: child,
                ),
              ),
              child: Material(
                color: AppColors.charcoal,
                elevation: 10,
                borderRadius: BorderRadius.circular(16),
                child: Semantics(
                  liveRegion: true,
                  container: true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            widget.isError
                                ? Icons.error_outline_rounded
                                : Icons.check_circle_outline_rounded,
                            color: widget.isError
                                ? AppColors.amber
                                : AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.sizeOf(context).height * .4,
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                widget.message,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 14,
                                  color: AppColors.pureWhite,
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close message',
                          onPressed: widget.onDismiss,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
      showAppFeedback(context, message);
    }
    return false;
  }
}

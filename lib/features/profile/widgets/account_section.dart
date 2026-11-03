import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

/// Account roles keep settings, actions and editor fields on the same scale.
abstract final class AccountType {
  static final row = AppTypography.bodyLarge.copyWith(
    fontWeight: FontWeight.w500,
  );
  static final detail = AppTypography.bodyMedium.copyWith(fontSize: 13);
  static final value = AppTypography.monoSmall.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static final section = AppTypography.headlineSmall.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
}

class AccountSurface extends StatelessWidget {
  const AccountSurface({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => GlassCard(
    blur: true,
    sharedBackdrop: true,
    repaintBoundary: true,
    border: false,
    boxShadow: const [],
    padding: EdgeInsets.zero,
    child: child,
  );
}

class AccountSection extends StatelessWidget {
  const AccountSection({
    super.key,
    required this.title,
    required this.children,
    this.action,
  });
  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: AccountType.section),
              ),
            ),
            if (action != null) action!,
          ],
        ),
      ),
      AccountSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const AccountDivider(),
              children[i],
            ],
          ],
        ),
      ),
    ],
  );
}

class AccountDivider extends StatelessWidget {
  const AccountDivider({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Divider(height: 1, thickness: 1, color: AppColors.subtleBorder),
  );
}

/// A full-width row, with values moved below the label at larger text sizes.
class AccountRow extends StatelessWidget {
  const AccountRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.value,
    this.numeric = false,
    this.onTap,
    this.accessory,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? value;
  final bool numeric;
  final VoidCallback? onTap;
  final Widget? accessory;

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              ExcludeSemantics(
                child: Icon(icon, size: 20, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stackValue =
                      MediaQuery.textScalerOf(context).scale(16) > 22 ||
                      constraints.maxWidth < 240;
                  final valueText = value == null
                      ? null
                      : Text(
                          value!,
                          style: numeric
                              ? AccountType.value
                              : AccountType.row.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          textAlign: stackValue
                              ? TextAlign.start
                              : TextAlign.end,
                        );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (stackValue) ...[
                        Text(title, style: AccountType.row),
                        if (valueText != null) ...[
                          const SizedBox(height: 4),
                          valueText,
                        ],
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(title, style: AccountType.row),
                            ),
                            if (valueText != null) ...[
                              const SizedBox(width: 12),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth * .5,
                                ),
                                child: valueText,
                              ),
                            ],
                          ],
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!, style: AccountType.detail),
                      ],
                    ],
                  );
                },
              ),
            ),
            if (accessory != null || onTap != null) ...[
              const SizedBox(width: 8),
              ExcludeSemantics(
                child:
                    accessory ??
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
    return onTap == null ? content : InkWell(onTap: onTap, child: content);
  }
}

/// Uses Flutter's menu semantics, focus, dismissal and selected-item feedback.
class AccountChoiceRow<T> extends StatelessWidget {
  const AccountChoiceRow({
    super.key,
    required this.title,
    required this.value,
    required this.label,
    required this.choices,
    required this.onSelected,
    this.subtitle,
    this.icon,
    this.numeric = false,
  });
  final String title;
  final T value;
  final String label;
  final Map<T, String> choices;
  final ValueChanged<T> onSelected;
  final String? subtitle;
  final IconData? icon;
  final bool numeric;

  @override
  Widget build(BuildContext context) => PopupMenuButton<T>(
    tooltip: 'Change $title',
    initialValue: value,
    onSelected: onSelected,
    itemBuilder: (context) => [
      for (final choice in choices.entries)
        CheckedPopupMenuItem<T>(
          value: choice.key,
          checked: choice.key == value,
          child: Text(choice.value, style: AccountType.row),
        ),
    ],
    child: AccountRow(
      title: title,
      subtitle: subtitle,
      value: label,
      icon: icon,
      numeric: numeric,
      accessory: const Icon(
        Icons.unfold_more_rounded,
        size: 20,
        color: AppColors.textMuted,
      ),
    ),
  );
}

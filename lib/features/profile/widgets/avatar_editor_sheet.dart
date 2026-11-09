import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/avatar_reference.dart';
import '../providers/avatar_editor_provider.dart';
import '../providers/profile_provider.dart';
import 'profile_avatar.dart';

Future<void> showAvatarEditor(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => const AvatarEditorSheet(),
    );

class AvatarEditorSheet extends ConsumerWidget {
  const AvatarEditorSheet({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(avatarEditorProvider);
    final editor = ref.read(avatarEditorProvider.notifier);
    final profile = ref.watch(accountProfileProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final textScale = MediaQuery.textScalerOf(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final duration = Duration(milliseconds: reduced ? 0 : 220);
    return PopScope(
      canPop: !state.busy,
      child: SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .9,
          ),
          decoration: const BoxDecoration(
            color: AppColors.onyx,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: AppColors.subtleBorder)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.steel,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'PROFILE PICTURE',
                        style: AppTypography.headlineSmall.copyWith(
                          fontSize: 18,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: state.busy
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Choose a portrait or add your own photo.',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                accent.withValues(alpha: .14),
                                accent.withValues(alpha: .025),
                              ],
                            ),
                            border: Border.all(
                              color: accent.withValues(alpha: .18),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accent.withValues(alpha: .5),
                              ),
                            ),
                            child: Semantics(
                              label: 'Profile picture preview',
                              image: true,
                              child: ProfileAvatar(
                                reference: state.reference,
                                name: profile.displayName,
                                size: 112,
                                bytes: state.bytes,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = textScale.scale(13) > 20 ? 1 : 3;
                          final width =
                              (constraints.maxWidth - (columns - 1) * 8) /
                              columns;
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final source in AvatarSource.values)
                                SizedBox(
                                  width: width,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 14,
                                      ),
                                      minimumSize: const Size(44, 56),
                                      foregroundColor: AppColors.textPrimary,
                                      side: const BorderSide(
                                        color: AppColors.subtleBorder,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: state.busy
                                        ? null
                                        : () => editor.pick(source),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          switch (source) {
                                            AvatarSource.gallery =>
                                              Icons.photo_library_outlined,
                                            AvatarSource.camera =>
                                              Icons.camera_alt_outlined,
                                            AvatarSource.files =>
                                              Icons.folder_open_rounded,
                                          },
                                          color: state.busy
                                              ? AppColors.textMuted
                                              : accent,
                                          size: 22,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          switch (source) {
                                            AvatarSource.gallery => 'Gallery',
                                            AvatarSource.camera => 'Camera',
                                            AvatarSource.files => 'Files',
                                          },
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                                fontSize: 14,
                                                color: AppColors.textPrimary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'THE PORTRAIT COLLECTION',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = textScale.scale(12) > 20 ? 2 : 4;
                          final width =
                              (constraints.maxWidth - (columns - 1) * 8) /
                              columns;
                          return Wrap(
                            spacing: 8,
                            runSpacing: 12,
                            children: [
                              for (final id in AvatarReference.presets)
                                SizedBox(
                                  width: width,
                                  child: Semantics(
                                    selected:
                                        state.reference ==
                                        AvatarReference.preset(id),
                                    button: true,
                                    label:
                                        '${id[0].toUpperCase()}${id.substring(1)} portrait',
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: state.busy
                                            ? null
                                            : () => editor.select(
                                                AvatarReference.preset(id),
                                              ),
                                        child: AnimatedContainer(
                                          duration: duration,
                                          curve: Curves.easeInOutCubic,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            color:
                                                state.reference ==
                                                    AvatarReference.preset(id)
                                                ? accent.withValues(alpha: .08)
                                                : Colors.transparent,
                                            border: Border.all(
                                              color:
                                                  state.reference ==
                                                      AvatarReference.preset(id)
                                                  ? accent
                                                  : Colors.transparent,
                                            ),
                                          ),
                                          child: ExcludeSemantics(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Stack(
                                                  children: [
                                                    ProfileAvatar(
                                                      reference:
                                                          AvatarReference.preset(
                                                            id,
                                                          ),
                                                      name: '',
                                                      size: (width - 16).clamp(
                                                        44,
                                                        68,
                                                      ),
                                                    ),
                                                    if (state.reference ==
                                                        AvatarReference.preset(
                                                          id,
                                                        ))
                                                      Positioned(
                                                        right: 0,
                                                        bottom: 0,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                3,
                                                              ),
                                                          decoration:
                                                              BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color: accent,
                                                                border: Border.all(
                                                                  color:
                                                                      AppColors
                                                                          .onyx,
                                                                  width: 2,
                                                                ),
                                                              ),
                                                          child: const Icon(
                                                            Icons.check_rounded,
                                                            size: 12,
                                                            color:
                                                                AppColors.onyx,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${id[0].toUpperCase()}${id.substring(1)}',
                                                  textAlign: TextAlign.center,
                                                  style: AppTypography
                                                      .bodyMedium
                                                      .copyWith(
                                                        fontSize: 14,
                                                        color:
                                                            state.reference ==
                                                                AvatarReference.preset(
                                                                  id,
                                                                )
                                                            ? accent
                                                            : AppColors
                                                                  .textSecondary,
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
                            ],
                          );
                        },
                      ),
                      if (state.reference != null) ...[
                        const SizedBox(height: 14),
                        TextButton.icon(
                          onPressed: state.busy
                              ? null
                              : () => editor.select(null),
                          icon: const Icon(
                            Icons.person_outline_rounded,
                            size: 18,
                          ),
                          label: const Text('Use my initials'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            minimumSize: const Size(44, 44),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.subtleBorder),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.error != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          state.error!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton(
                      onPressed: state.busy || !state.changed
                          ? null
                          : () async {
                              if (await editor.save() && context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(44, 52),
                        disabledBackgroundColor: AppColors.surfaceSecondary,
                        disabledForegroundColor: AppColors.textMuted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: state.busy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                                semanticsLabel: 'Preparing picture',
                              ),
                            )
                          : const Text('Save picture'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

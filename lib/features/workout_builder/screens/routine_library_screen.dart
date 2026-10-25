import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/acrylic_card.dart';
import '../models/split_model.dart';
import '../providers/splits_provider.dart';
import '../widgets/create_routine_sheet.dart';

/// Full-featured Routine Library & Template Builder Screen.
///
/// Complies with:
/// - Apple HIG: All font sizes >= 11.0 pt, min 4.5:1 WCAG AA contrast.
/// - 2-Accent system: Electric Cyan primary CTA, Slate/Silver neutral chrome.
/// - Standard gym terminology: no pseudo-military or sci-fi words.
class RoutineLibraryScreen extends ConsumerStatefulWidget {
  const RoutineLibraryScreen({super.key});

  @override
  ConsumerState<RoutineLibraryScreen> createState() => _RoutineLibraryScreenState();
}

class _RoutineLibraryScreenState extends ConsumerState<RoutineLibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openRoutineEditor({TrainingSplitModel? splitToEdit}) {
    showCreateRoutineSheet(context, initialSplit: splitToEdit);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(splitsProvider);
    final notifier = ref.read(splitsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.pureWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ROUTINE LIBRARY',
          style: AppTypography.headlineMedium.copyWith(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppColors.pureWhite,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelColor: AppColors.pureWhite,
          unselectedLabelColor: AppColors.platinum,
          labelStyle: AppTypography.labelSmall.copyWith(
            fontSize: 12.0,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
          unselectedLabelStyle: AppTypography.labelSmall.copyWith(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
          tabs: [
            Tab(text: 'PRESET SPLITS (${state.presetSplits.length})'),
            Tab(text: 'MY ROUTINES (${state.customSplits.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRoutineEditor(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onyx,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          'NEW ROUTINE',
          style: AppTypography.labelSmall.copyWith(
            fontSize: 12.0,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.onyx,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: Preset Splits ──────────────────────────────────────────
          _buildSplitList(
            splits: state.presetSplits,
            activeSplitId: state.activeSplitId,
            notifier: notifier,
            isCustomTab: false,
          ),

          // ── TAB 2: Custom Routines ────────────────────────────────────────
          state.customSplits.isEmpty
              ? _buildEmptyCustomState()
              : _buildSplitList(
                  splits: state.customSplits,
                  activeSplitId: state.activeSplitId,
                  notifier: notifier,
                  isCustomTab: true,
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyCustomState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.steel),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Custom Routines Yet',
              style: AppTypography.headlineMedium.copyWith(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: AppColors.pureWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a tailored workout routine or duplicate any preset split to modify its exercises and days.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 12.5,
                color: AppColors.platinum,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openRoutineEditor(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'CREATE CUSTOM ROUTINE',
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.onyx,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pureWhite,
                foregroundColor: AppColors.onyx,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitList({
    required List<TrainingSplitModel> splits,
    required String activeSplitId,
    required SplitsNotifier notifier,
    required bool isCustomTab,
  }) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: splits.length,
      itemBuilder: (context, index) {
        final split = splits[index];
        final isActive = split.id == activeSplitId;

        return AcrylicCard(
          borderRadius: 16,
          margin: const EdgeInsets.only(bottom: 14),
          borderColor: isActive
              ? AppColors.primary
              : AppColors.steel.withValues(alpha: 0.70),
          borderWidth: isActive ? 1.5 : 1.0,
          glowColor: isActive ? Colors.white.withValues(alpha: 0.08) : null,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isActive) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11.0,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${split.daysPerWeek} DAYS / WK',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.platinum,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${split.totalWeeklySets} TOTAL SETS',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.platinum,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      split.name,
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 17.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pureWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      split.description,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12.5,
                        color: AppColors.platinum,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.steel),

              // ── Days preview ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WORKOUT DAYS',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.platinum,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...split.workouts.map((w) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: w.isRestDay ? AppColors.platinum : AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                w.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.pureWhite,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              w.isRestDay ? 'Rest' : '${w.exercises.length} ex · ${w.totalSets} sets',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11.0,
                                color: AppColors.platinum,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.steel),

              // ── Bottom Action Row ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    if (!isActive)
                      FilledButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          notifier.switchActiveSplit(split.id);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.pureWhite,
                          foregroundColor: AppColors.onyx,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'SET AS ACTIVE',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppColors.onyx,
                          ),
                        ),
                      ),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (!isCustomTab) ...[
                          // Customize button for presets (clones and opens editor immediately)
                          TextButton.icon(
                            onPressed: () async {
                              HapticFeedback.selectionClick();
                              final cloned = await notifier.duplicateSplit(split.id);
                              if (context.mounted) {
                                _openRoutineEditor(splitToEdit: cloned);
                              }
                            },
                            icon: const Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
                            label: Text(
                              'CUSTOMIZE',
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                        if (isCustomTab) ...[
                          // Edit button for custom routines
                          TextButton.icon(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _openRoutineEditor(splitToEdit: split);
                            },
                            icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                            label: Text(
                              'EDIT',
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                        // Duplicate button
                        TextButton.icon(
                          onPressed: () async {
                            HapticFeedback.selectionClick();
                            final cloned = await notifier.duplicateSplit(split.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.charcoal,
                                  content: Text(
                                    'Created duplicate: ${cloned.name}',
                                    style: const TextStyle(fontSize: 12.0, color: AppColors.pureWhite),
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.platinum),
                          label: Text(
                            'DUPLICATE',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.platinum,
                            ),
                          ),
                        ),
                        if (isCustomTab) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Delete Routine',
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.warning),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.charcoal,
                                  title: Text(
                                    'Delete Routine?',
                                    style: AppTypography.headlineMedium.copyWith(
                                      fontSize: 16.0,
                                      color: AppColors.pureWhite,
                                    ),
                                  ),
                                  content: Text(
                                    'Are you sure you want to delete "${split.name}"? This cannot be undone.',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 12.5,
                                      color: AppColors.platinum,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('CANCEL', style: TextStyle(color: AppColors.platinum)),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        notifier.deleteCustomSplit(split.id);
                                      },
                                      style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
                                      child: const Text('DELETE', style: TextStyle(color: AppColors.onyx)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


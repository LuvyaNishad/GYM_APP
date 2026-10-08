import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/liquid_glass.dart';
import '../../../state/app_providers.dart';
import '../widgets/radar_chart_widget.dart';
import '../widgets/recovery_status_widget.dart';

/// LEON Command Center — Main Tactical Dashboard Screen
///
/// Features:
/// - Cyber-slate tactical HUD header with live telemetry & operative ID
/// - Hero training assignment module with one-tap session initiation
/// - Biometric readiness sensor with live ECG waveform
/// - 3-Axis load symmetry radar with real-time advisory
/// - 4-Way tactical quick action matrix with dedicated routing
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSplit = ref.watch(activeSplitProvider);
    final splitTitle = activeSplit?.name ?? 'TACTICAL PUSH // PROTOCOL A';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Tactical HUD App Bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 90,
            floating: true,
            snap: true,
            backgroundColor: AppColors.background.withValues(alpha: 0.95),
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.success,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success.withValues(alpha: 0.8),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'SYS.ONLINE // V1.0',
                            style: AppTypography.labelSmall.copyWith(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 8.5,
                              letterSpacing: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppConstants.appName,
                        style: AppTypography.displayMedium.copyWith(
                          color: AppColors.primary,
                          fontSize: 24,
                          letterSpacing: 3.5,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push(AppConstants.routeProfile);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            color: AppColors.primary,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'OP-01',
                            style: AppTypography.labelSmall.copyWith(
                              fontFamily: 'JetBrains Mono',
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Dashboard Body ────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              AppShell.reservedBottomSpace + 16,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── 1. Hero Protocol Assignment Card ────────────────────────
                _HeroAssignmentCard(
                  splitName: splitTitle,
                  onEngage: () {
                    HapticFeedback.heavyImpact();
                    context.push(AppConstants.routeWorkoutSession);
                  },
                ),
                const SizedBox(height: 18),

                // ── 2. Biometric Recovery Status ─────────────────────────────
                const RecoveryStatusWidget(),
                const SizedBox(height: 18),

                // ── 3. Load Symmetry Radar Card ──────────────────────────────
                const GlassCard(
                  child: RadarChartWidget(),
                ),
                const SizedBox(height: 24),

                // ── 4. Tactical Operations Grid ──────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TACTICAL MODULES',
                      style: AppTypography.labelSmall.copyWith(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _TacticalModuleTile(
                        icon: Icons.tune_rounded,
                        title: 'BUILDER',
                        subtitle: 'Attache Case',
                        accentColor: AppColors.primary,
                        onTap: () => context.go(AppConstants.routeWorkoutBuilder),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TacticalModuleTile(
                        icon: Icons.local_fire_department_rounded,
                        title: 'DATABASE',
                        subtitle: 'Movement Index',
                        accentColor: AppColors.secondary,
                        onTap: () => context.go(AppConstants.routeExerciseLibrary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TacticalModuleTile(
                        icon: Icons.insights_rounded,
                        title: 'TELEMETRY',
                        subtitle: 'Progress Log',
                        accentColor: AppColors.purple,
                        onTap: () => context.go(AppConstants.routeAnalytics),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TacticalModuleTile(
                        icon: Icons.monitor_heart_outlined,
                        title: 'VITALS',
                        subtitle: 'Health Sync',
                        accentColor: AppColors.success,
                        onTap: () => context.push(AppConstants.routeHealthTracking),
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Prominent Hero Assignment banner for immediate workout initiation.
class _HeroAssignmentCard extends StatelessWidget {
  const _HeroAssignmentCard({
    required this.splitName,
    required this.onEngage,
  });

  final String splitName;
  final VoidCallback onEngage;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      borderRadius: 24,
      blurSigma: 24,
      glowColor: AppColors.primary.withValues(alpha: 0.22),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ACTIVE PROTOCOL',
                      style: AppTypography.labelSmall.copyWith(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 9,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'TARGET RPE 8.5',
                style: AppTypography.labelSmall.copyWith(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            splitName.toUpperCase(),
            style: AppTypography.headlineMedium.copyWith(
              fontSize: 18,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '5 EXERCISES  •  ~48 MIN  •  HYPERTROPHY FOCUS',
            style: AppTypography.bodySmall.copyWith(
              fontFamily: 'JetBrains Mono',
              color: AppColors.textSecondary,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 18),
          LiquidGlassButton(
            height: 48,
            accentColor: AppColors.primary,
            onPressed: onEngage,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'COMMENCE OPERATION',
                  style: AppTypography.titleLarge.copyWith(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tactical Glass Module Tile for the dashboard grid.
class _TacticalModuleTile extends StatelessWidget {
  const _TacticalModuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      glowColor: accentColor.withValues(alpha: 0.1),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              Icon(
                Icons.arrow_outward_rounded,
                color: AppColors.textMuted,
                size: 15,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTypography.titleLarge.copyWith(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

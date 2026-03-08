import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_page_widget.dart';
import '../../../core/constants/app_constants.dart';

/// Multi-step onboarding flow for new LEON users.
///
/// Guides the user through: Welcome → Goals → Weight Setup → Summary.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress indicator ──────────────────────────────────────────
            LinearProgressIndicator(
              value: (state.currentPage + 1) / OnboardingState.totalPages,
              backgroundColor: Colors.white12,
              color: const Color(0xFF00E5FF),
            ),

            // ── Page content ───────────────────────────────────────────────
            Expanded(
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: PageController(initialPage: state.currentPage),
                children: const [
                  OnboardingPageWidget(
                    title: 'Welcome to LEON',
                    subtitle:
                        'Your operational fitness OS.\nBuilt for performance.',
                    iconData: Icons.fitness_center_outlined,
                  ),
                  OnboardingPageWidget(
                    title: 'Set Your Goals',
                    subtitle:
                        'Strength. Hypertrophy. Endurance.\nChoose your mission.',
                    iconData: Icons.track_changes_outlined,
                  ),
                  OnboardingPageWidget(
                    title: 'Track Your Weight',
                    subtitle:
                        'Log your current and target weight\nto calibrate your plan.',
                    iconData: Icons.monitor_weight_outlined,
                  ),
                  OnboardingPageWidget(
                    title: 'Ready to Deploy',
                    subtitle: 'LEON is configured.\nBegin your first session.',
                    iconData: Icons.rocket_launch_outlined,
                  ),
                ],
              ),
            ),

            // ── Navigation buttons ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (state.currentPage > 0)
                    TextButton(
                      onPressed: notifier.previousPage,
                      child: const Text(
                        'BACK',
                        style: TextStyle(
                          color: Colors.white54,
                          fontFamily: 'JetBrainsMono',
                          letterSpacing: 1.5,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  FilledButton(
                    onPressed: () {
                      if (state.isLastPage) {
                        notifier.complete();
                        context.go(AppConstants.routeDashboard);
                      } else {
                        notifier.nextPage();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      state.isLastPage ? 'LAUNCH' : 'NEXT',
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

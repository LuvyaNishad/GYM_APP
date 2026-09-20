/// LEON main-tab shell.
///
/// Hosts the five main tab routes under a single floating [GlassNavPill]. The
/// pill floats *over* the tab content rather than reserving a strip below it —
/// that overlap is what gives the glass something to refract. Scrollable tab
/// content should pad its bottom by [AppShell.reservedBottomSpace] so the last
/// row can still be reached.
///
/// Full-screen routes (auth, onboarding, the OLED workout session) sit outside
/// this shell and have no pill.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'glass_nav_pill.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  /// Current router location, used to decide which tab reads as active.
  final String location;

  /// The tab screen being displayed.
  final Widget child;

  /// Space the floating pill covers at the bottom of the viewport, excluding
  /// the device's own safe-area inset.
  static const double reservedBottomSpace = GlassNavPill.height + _margin * 2;

  static const double _margin = 16;

  @override
  Widget build(BuildContext context) {
    final activeIndex = navPillIndexFor(location);

    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                0,
                24,
                _margin,
              ),
              child: GlassNavPill(
                activeIndex: activeIndex,
                onTabSelected: (int index) {
                  if (index == activeIndex) return;
                  context.go(kNavPillTabs[index].route);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

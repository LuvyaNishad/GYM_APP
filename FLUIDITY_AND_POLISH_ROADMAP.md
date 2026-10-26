# LEON / AEON — UI Polish, Fluidity, and Performance Implementation Roadmap

> **Purpose:** Turn the current Flutter fitness app into a coherent, polished, highly responsive product. This document is written for an implementation agent: it names the observed problems, target behavior, likely code locations, implementation patterns, and acceptance checks. Follow the phases in order so visual changes do not hide performance or navigation regressions.
>
> **Scope:** Flutter mobile app, Android emulator and physical Android devices first; preserve iOS behavior and keep layout adaptable to tablets, foldables, desktop-sized windows, large text, and reduced-motion preferences.
>
> **Current evidence:** The live Android emulator was inspected on October 26, 2026. Dashboard, Training Splits, Exercise Library, History, and Account were opened. Tab transitions slide horizontally and briefly expose adjacent screens. The Account screen's lower settings are covered by the floating navigation pill. History with no sessions leaves a large blank area. The exercise list is visually dense. A first-swipe hitch was reported by the user; it has not yet been measured in Flutter profile mode.

---

## Execution Status & Progress Tracker

| Chunk / Phase | Scope & Deliverables | Status | Verified In / Artifact |
|---|---|---|---|
| **Chunk 1: Nav Architecture & Bottom Clearance** | • Replaced full-width `PageView` with zero-peeking `IndexedStack`<br>• Added `TickerMode(enabled: isCurrent)` to pause offscreen tickers<br>• Added `PageStorageKey` to preserve per-tab scroll state<br>• Implemented dynamic `AppShell.bottomPadding(context)` accounting for `bottomInset`<br>• Verified all 5 main screen bottom controls scroll completely clear of pill | **COMPLETED** (Oct 26, 2026)<br>Git commit: `56ee426` | `chunk_1_verification.md`<br>`test/app_shell_slide_test.dart`<br>Emulator screenshots verified |
| **Chunk 2: State Updates & Rendering Optimization** | • Riverpod `.select(...)` fine-grained subscriptions for Dashboard bento cards (`StepsBentoCard`, `CaloriesBentoCard`, `WaterBentoCard`, `SleepBentoCard`)<br>• Exercise search debounce (150ms) and normalized catalog pre-indexing with `compute` isolate loading<br>• Custom painter equality checks (`listEquals` / `mapEquals`) and `RepaintBoundary` wrappers on radar charts and tempo wave | **COMPLETED** (Oct 26, 2026)<br>Git commit: pending | `chunk_2_verification.md`<br>`test/features/dashboard/dashboard_granular_rebuild_test.dart`<br>Emulator screenshots verified |
| **Chunk 3: Typography & Visual Foundation** | • Switch display headings to Outfit and numeric data to JetBrains Mono<br>• Enforce $\ge 11\text{sp}$ typography floor and $\ge 4.5:1$ contrast ratio<br>• Strict gym terminology cleanup | **PENDING** | Queued |
| **Chunk 4: Screen Density & Empty States** | • Refine History empty state with actionable next steps<br>• Reduce redundant chips and borders in Exercise Library and Account<br>• Active split and workout card visual hierarchy polish | **PENDING** | Queued |
| **Chunk 5: Multi-Device Polish & Profile Baseline** | • Responsive validation (compact, wide, landscape, $1.5\times$ text scaling)<br>• Automated profiler metrics (p50/p95/max frame times) | **PENDING** | Queued |

---

## 0. Product decisions and non-negotiable constraints

### 0.1 Resolve the product name before rebranding

The repository, `AGENTS.md`, and much of `DESIGN.md` call the product **LEON**. The installed Android app, launcher icon, onboarding welcome, some report exports, and some shared text say **AEON**. Do not perform a partial rename.

Before implementing a global branding change, select one name and update it as a single tracked change across:

- `pubspec.yaml`, Android application label and launcher resources, iOS display name and assets;
- app icon, onboarding, headers, login/signup, empty states, share/export copy, generated PDF metadata;
- comments and product documentation where useful.

Until the owner resolves it, keep user-facing product naming out of unrelated UI cleanup. Technical class/file names can be renamed in a dedicated migration with compilation and generated-code checks.

### 0.2 Honor existing app requirements

- Text minimum: **11sp** for every visible text element, including chart axes, chips, badges, buttons, and nav labels. Prefer 12–17sp for routine controls/body copy.
- Normal text contrast: target **4.5:1** minimum against the final rendered surface. Verify actual token pairs, including translucent overlays, with a contrast checker.
- Primary interaction accent: cyan `#00E5FF`; warning/calendar status accent: amber `#FFB300`; use restrained silver/slate for ordinary metrics. Do not add color solely for decoration.
- Use clean gym language. Avoid roleplay/UI copy such as “agent,” “callsign,” “deploy,” “protocol,” “operation,” “tactical,” and “telemetry.” Use “name,” “start workout,” “training split,” “activity,” and “training recommendation.”
- Keep the current dark appearance and true black active-workout canvas where it serves workout use. Do not introduce competing color systems.
- Prefer Riverpod for shared/business state. Local widget state is appropriate for ephemeral focus, drag, press, and animation state.
- Never hand-edit generated `*.freezed.dart` or `*.g.dart` files.

### 0.3 Define “fluid” with measurable outcomes

Fluidity means that input is acknowledged immediately, motion follows intent, scrolling does not hitch, and layouts do not jump or clip. Do not equate it with adding more animations.

Use these initial targets on representative mid-range Android hardware in **profile** mode:

- No synchronous disk reads, JSON decoding, filtering of the entire catalog, or chart aggregation on the UI thread during pointer movement or build.
- Keep UI and raster frame times within the active display budget for at least 95% of frames during a repeatable tab-change, list-scroll, and workout-logging scenario. For a 60 Hz panel the budget is about 16.7 ms; for 90 Hz about 11.1 ms; for 120 Hz about 8.3 ms. Record actual device refresh rate and report p50/p95/max; do not claim a universal pass from one emulator.
- No blank/old frame or touch lock during tab changes. Show pressed feedback on pointer down and commit on pointer up.
- First visit to each main tab should not trigger expensive synchronous work during a horizontal gesture. Preserve useful tab state without keeping every heavy animation alive.
- At 1.3× and 1.5× system text scale, every primary action stays visible/reachable; labels wrap or reflow rather than clip.
- Reduce blur, animation, and visual complexity under reduced-transparency, reduced-motion, battery-saver, and low-performance conditions when supported.

---

## 1. Audit summary from the live build

### What is working and should survive the redesign

- Dark palette and high-contrast primary workout action make the fitness purpose clear.
- Dashboard content is understandable: selected day, scheduled workout, start action, and activity cards.
- Exercise Library has a clear search-first structure and visible filter controls.
- Training Splits communicates the active split and available routines.
- Main navigation has visible text labels, which is helpful for discoverability and accessibility.

### Confirmed live issues

1. **Account bottom content is occluded.** The rest-timer choices sit behind the nav pill at the visible scroll boundary. Every scrollable main tab must reserve enough bottom space for the pill plus safe-area inset, and this must be verified at the last scroll offset.
2. **Main-tab transition exposes adjacent screens.** The horizontal `PageView` paints neighboring pages during the slide. It is visually distracting, and likely makes the first gesture pay for building or rasterizing another substantial route.
3. **First-swipe hitch is plausible from the implementation, not yet benchmarked.** Five feature screens live in one `PageView`; `_KeepAliveTab` retains all five. A cold destination can construct large widget trees, provider consumers, charts, and animation controllers while the gesture is active.
4. **History empty state wastes the content area.** “No workouts found” appears in a small center region under the calendar and segment/filter controls, with a large unused vertical region and no useful next action.
5. **Exercise cards have high repeated density.** Several chips, level tags, target text, and a separate add circle repeat for each row. The list shows relatively few exercises per viewport.
6. **Account uses many nested boxed groups.** The page contains the profile header, biometrics grid, progress, preferences, chips, and controls, with dividers/borders around most pieces. Density and the bottom overlap compete with a premium feel.
7. **Visual identity is inconsistent with the written system.** The live app uses an angular/pixel-like display face and mostly white selected states; `app_typography.dart` names Nano and Plus Jakarta Sans. The current design doc specifies Outfit and JetBrains Mono. The live heading font reads more like a game interface than a refined fitness product.
8. **Name and terminology drift.** Source uses both LEON and AEON; old onboarding/technical naming remains in code and model fields. `AGENTS.md`, `DESIGN.md`, and implementation choices also disagree on accent and glass details.
9. **Performance has not been quantified.** Screenshot-driven interaction establishes visible behavior, not frame-time, shader compilation, memory, or cold-start numbers. Capture a baseline before optimization and compare afterward on a real device as well as an emulator.

---

## 2. Phase 1 — Establish the visual and product foundation

### 2.1 Reconcile product guidance

Update the authoritative design guidance so it agrees with `AGENTS.md` and current product decisions. Retire contradictory requirements such as “every card must blur,” 24px blur on all cards, minimum `Outfit` heading tracking of 1.5 everywhere, and multiple decorative muscle-group neons. Keep a short token source of truth in code and link the design doc to it.

Create/update one semantic token file, preferably `lib/core/theme/app_colors.dart` and `app_typography.dart`, and use it everywhere. Tokens should be semantic rather than component-specific:

```dart
abstract final class AppColors {
  static const canvas = Color(0xFF10131B);
  static const surface = Color(0xFF1B1E27);
  static const surfaceRaised = Color(0xFF242833);
  static const borderSubtle = Color(0xFF373D49);
  static const contentPrimary = Color(0xFFF5F6F8);
  static const contentSecondary = Color(0xFFB8C0CE);
  static const contentMuted = Color(0xFF929DAD);
  static const actionPrimary = Color(0xFF00E5FF);
  static const statusWarning = Color(0xFFFFB300);
  static const statusDanger = Color(0xFFFF6B6B);
  static const statusSuccess = Color(0xFF62C98B);
}
```

These values are starting points, not a mandate to copy blindly. Check contrast after layering and adjust tokens to pass 4.5:1. Avoid relying on opacity washes for small text.

Replace arbitrary raw color literals in app UI with semantic tokens. Keep a documented exception for Olympic plate colors in the plate calculator because plate colors represent equipment standards, not brand accents.

### 2.2 Typography direction

- Use **Outfit** for headings, controls, labels, and body copy, subject to legibility testing on Android and iOS.
- Use **JetBrains Mono** for weights, reps, timers, dates where fixed-width alignment helps, set/rep tables, and chart numerical values.
- Do not render a whole heading in the display font at extreme tracking. Use a compact type scale with restrained tracking; large text should usually have tighter or neutral tracking, not expanded spacing.
- Keep ordinary copy in sentence case. Use all caps only for compact category eyebrows when the content genuinely benefits from that treatment.
- Use `MediaQuery.textScalerOf(context)` behavior naturally; do not set `textScaler: TextScaler.noScaling` for product UI.
- Audit all explicit `fontSize` values and all `copyWith` overrides; no text can fall below 11sp.

Add named typography styles for display, screen title, section title, body, supporting body, button, metric, and data label. Set coherent line heights. Do not introduce a third/fourth font family into active UI.

### 2.3 Color hierarchy

- Cyan means primary action, selected/active interaction, or active workout state.
- Amber means warning or selected calendar date.
- Success and danger colors are only used for their respective states and always paired with text/icon/shape so color is not the only signal.
- Muscle categories use restrained identifiers. If colors are needed for chart interpretation, label categories directly and keep the chart palette low-saturation/cohesive. Do not use unrelated orange/purple/yellow neon across general cards.
- White remains a neutral foreground, not a competing primary accent for every selected/primary state.

### 2.4 Shape, spacing, and restraint

Adopt a small token scale, not hard constraints on every widget:

```text
Spacing: 4, 8, 12, 16, 24, 32
Control radius: 12–16
Card radius: 18–22
Sheet top radius: 24
Screen side inset: 20–24 on phones, responsive max-width on wide layouts
Minimum touch size: 44 × 44 logical pixels
```

Use background/surface contrast and spacing first. Add a border only when it defines an interactive boundary or separates similar adjacent surfaces. Avoid drawing a border around every chip inside a bordered card. Use shadows/glows sparingly; the current nav glow/lamp is a signature effect and should be softened to a single quiet selected indicator.

---

## 3. Phase 2 — Navigation architecture and the first-swipe hitch

### 3.1 First choice: tap-based primary tab navigation

The most direct way to remove the cold horizontal swipe hitch is to stop making all five main destinations siblings in a full-width `PageView`. People already have a labeled five-item bottom navigation. Keep it as the primary tab navigation and let taps move between tab routes. This also removes the accidental page swipe interaction and adjacent-screen peeking.

Relevant code:

- `lib/shared/widgets/app_shell.dart`: `_AppShellState`, `_tabScreens`, `PageView`, `_onPageChanged`, `_onTabSelected`, `_KeepAliveTab`.
- `lib/shared/widgets/glass_nav_pill.dart`: `GlassNavPill`, `kNavPillTabs`, `navPillIndexFor`.
- `lib/core/router/app_router.dart`: shell route and tab route hierarchy.

Implementation steps:

1. Decide whether GoRouter's `StatefulShellRoute.indexedStack` can host the five persistent tab branches. Prefer this if it fits the current route structure; each branch naturally maintains its own navigation/scroll state.
2. Otherwise, use an `IndexedStack` with an explicit selected index. Do not animate by translating all five screens across the viewport.
3. Preserve each scroll offset with stable `PageStorageKey<String>` values or route branch state. Give nested lists distinct keys.
4. Call the router's tab navigation method once per tap; remove bidirectional animation/route updates that can race or double-trigger.
5. Keep back-stack semantics explicit: a tab tap changes top-level selection; back within a tab pops its pushed detail route before leaving the app.
6. If simple crossfade improves orientation, fade only the content for 120–180ms. Avoid a horizontal slide that exposes another complete page.
7. Keep labels visible. Make every item at least 44×44, with a semantic label and selected state.

### 3.2 If horizontal swipe is retained as a secondary gesture

Only retain it after profiling proves it performs well and usability testing says it is valuable. Avoid attaching a `PageView` that mounts every expensive route on first movement.

- Build pages lazily with `PageView.builder`, but understand that a page may still be built as it approaches the viewport.
- Preload only the immediate next page after the first frame/idle callback; do not synchronously initialize all five during startup.
- Use `TickerMode(enabled: index == currentIndex)` around each tab page and make any custom controller explicitly respond to ticker muting if needed.
- Do not eagerly keep every full tab alive. Preserve only lightweight route/scroll state; dispose heavy, reconstructible chart view state when appropriate.
- Use `RepaintBoundary` for isolated expensive charts and animated painters after profiling; do not add one around every widget.
- Confirm that direction changes and interrupted gestures begin from the current visual position. Do not lock touches during a transition.

### 3.3 Fix programmatic route synchronization

The present shell tracks `_currentIndex`, route `location`, and `PageController` separately. Consolidate selection so the router is canonical or a single navigation controller is canonical. Avoid race conditions from `animateToPage(...).then(...)`, rapid repeated tab taps, deep links, restored routes, and swipes. Make stale completions harmless; only apply completion state if it still matches the latest target.

---

## 4. Phase 3 — Smooth rendering and state update scope

### 4.1 Profile before changing rendering code

Use a repeatable profile session on an emulator and a physical mid-range Android phone. Build/install profile mode, connect Flutter DevTools, and capture the Performance timeline and frame chart. Run exactly these scenarios:

1. Cold launch to dashboard, first frame, and first interactive frame.
2. Tap each main tab once, including the first visit and a repeat visit.
3. Scroll the Dashboard from top to bottom and back.
4. Scroll Exercise Library rapidly, then search, clear search, and change filters.
5. Scroll Account to the final setting and back.
6. Open History sessions, overload, and radar sections.
7. Start a workout, log a set, show rest timer, dismiss, and continue.
8. Repeat with the app backgrounded/resumed and with a larger text scale.

Record device/model, OS, Flutter version, refresh rate, profile/release mode, UI frame p50/p95/max, raster frame p50/p95/max, missed-frame counts, memory after tab sequence, and cold/warm results. Compare before/after under the same conditions. Screenshots cannot establish frame-time performance.

### 4.2 Reduce broad Riverpod rebuilds on Dashboard

`DashboardScreen` currently watches the entire `dailyTelemetryProvider`, then passes a large telemetry object to Steps, Calories, Water, and Sleep. A step update can rebuild the dashboard ancestor and multiple sibling cards.

Refactor each independently changing card to watch only its own projection:

```dart
final steps = ref.watch(
  dailyTelemetryProvider.select((value) => value.steps),
);
```

For multiple fields, use a small immutable selected value with equality, or separate providers for independently changing values. Avoid selecting a newly allocated `Map`/list each build unless equality is defined. Keep stable static subtrees `const` and split consumers at the smallest meaningful boundary.

Target files include `dashboard_screen.dart`, `daily_telemetry_model.dart`, `steps_bento_card.dart`, `calories_bento_card.dart`, `water_bento_card.dart`, `sleep_bento_card.dart`, `retractable_calendar_header.dart`, and provider files.

### 4.3 Move expensive work off build and gesture paths

- Do not parse exercise JSON, compute fuzzy search scores, sort all results, aggregate full workout history, or derive chart series inside `build()`.
- Normalize exercise search fields once when the catalog is loaded. Store lowercased searchable text/tokens or precomputed indexes in repository memory.
- Debounce free-text search around 120–180ms with a cancellable timer/provider. Cancel stale work and display matching results only for the current query.
- If the catalog or aggregation becomes large, move CPU-bound parsing/aggregation to `compute`/an isolate, passing only serializable inputs and returning compact results. Measure crossover first; isolates have message/copy overhead.
- Cache derived chart data by a stable key such as selected date range, filter, and source revision. Invalidate on workout mutation rather than rebuilding every frame.
- Avoid creating new closures, formatters, gradients, painters, or expensive objects repeatedly inside animated `build()` methods. Hoist immutable values to `const`, final fields, or memoized selectors when appropriate.

### 4.4 Lists and scroll surfaces

- Use `ListView.builder`, `SliverList`, and `SliverGrid` for variable/large collections. Avoid constructing every row inside a `Column` or `SingleChildScrollView`.
- In mixed pages use one `CustomScrollView` with slivers rather than nested vertical scrollables. Use nested scrolling only for a clear product need.
- For fixed-height rows, set `itemExtent`; for a representative fixed prototype, use `prototypeItem`; only use these when content truly honors the constraint at large text scales.
- Do not add `cacheExtent` indiscriminately. Profile first; modest prefetch can hide latency, but excessive prebuild increases memory and first-frame cost.
- Avoid wrapping each simple list row in `BackdropFilter`. A solid surface is cheaper and often more legible.
- Keep scroll physics consistent within a platform; avoid nested horizontal scroll gestures fighting the top-level page swipe.
- Use stable keys for reordered workout rows and stateful exercise cards so state follows data, not position.

### 4.5 Blur and raster cost

There are 24 `BackdropFilter` / `ImageFilter.blur` occurrences in app Dart code, spread across shared glass surfaces and feature sheets/cards. Blur causes offscreen compositing and can become costly over long scrolling content.

- Restrict live blur to a few floating functional layers: navigation, modal sheets, and perhaps one transient overlay.
- Render ordinary scrolling cards as opaque or near-opaque semantic surface colors with a subtle border. Keep translucency only where it improves layering and text remains legible.
- Use `ClipRect`/`ClipRRect` to limit the blur region to the smallest necessary bounds.
- Avoid stacking blurred parent and child materials.
- Prefer a static gradient/solid tint for large backgrounds over a full-screen `BackdropFilter`.
- Add a reduced-transparency mode that replaces blur with a more opaque surface.
- Profile shader compilation and raster timings on low-end GPU devices. Do not infer blur cost from emulator-only smoothness.

### 4.6 Custom charts and animation repaint scope

- Inspect every `CustomPainter.shouldRepaint`. It should compare only immutable values that affect painting; use `oldDelegate.value != value`, not unconditional `true`.
- Separate static chart grid/axes from animated value/trace layers so the grid is not repainted every tick.
- Wrap isolated charts in `RepaintBoundary` when DevTools shows repaint propagation. Keep painting bounded to chart dimensions.
- Avoid `saveLayer`, repeated clipping, broad opacity layers, and per-point shadows unless the chart design requires them and profiling permits.
- Downsample large line/step histories to pixel resolution before painting. Drawing more points than horizontal device pixels adds work without visible value.
- Never calculate chart aggregates in a painter callback. Precompute points in provider/repository state.
- Give charts labels, a summary in text, and semantics; a canvas alone is not accessible.

### 4.7 Timers, sensors, and app lifecycle

- Use monotonic elapsed-time calculation for rest/workout timers: store a target `DateTime`/elapsed anchor, and derive displayed remaining time at each tick. Timer callbacks can drift and may pause in background; recalculate on resume.
- Keep the 1-second update limited to the timer text/progress region, not the full workout tree.
- Cancel `Timer`, `Ticker`, stream subscriptions, and animation controllers in `dispose`/provider `ref.onDispose`.
- Pause nonessential animations when the app is inactive or a tab is offscreen. Do not keep a pedometer subscription alive if product requirements do not need background counting; document the required lifecycle and permission behavior.
- Use `WidgetsBindingObserver` or app lifecycle-aware Riverpod logic for resume/re-poll without rebuilding the whole app.

---

## 5. Phase 4 — Motion design and interaction feel

### 5.1 Motion principles

- Pointer down: immediate visual pressed feedback. Pointer up: commit if the pointer remains inside the hit target. Drag away: cancel.
- Use motion to explain a state change or maintain spatial continuity, not as decoration.
- Start interrupted animations from their current displayed value. Rapid taps should retarget cleanly rather than queue stale animations.
- Normal tap/state transition: 120–200ms. Route/content transition: 160–240ms. Sheet movement should follow drag continuously and settle according to release direction/velocity.
- Use ease-out for entering elements and ease-in for leaving elements. Avoid elastic bounce on ordinary selection, tab navigation, and initial onboarding.
- Prefer `FadeTransition`, `SlideTransition`, `AnimatedContainer`, `AnimatedSwitcher`, or `TweenAnimationBuilder` only where they fit. Do not put a `setState` around a large tree at animation frame frequency.
- Add a `MediaQuery.disableAnimations` or accessibility-aware policy: replace long spatial transitions/loops with a quick fade or immediate state change.

### 5.2 Navigation motion

After removing the top-level slide, transition only the selected tab content with a restrained fade or no transition. Selection should update at tap time. The active indicator may animate over 150–200ms; remove the current bright lamp bar, large surrounding glow, and active scale if it draws attention away from the content.

### 5.3 Buttons, chips, steppers

- Provide 44×44dp minimum hit regions even if the visible icon is smaller. `IconButton` constraints should not be collapsed.
- Use a subtle pressed surface/tint/scale around 0.98 for 100–140ms; no large glow on every press.
- Ensure `InkResponse`/`InkWell` ripple or equivalent visible feedback is present and clipped to the shape.
- Disable double submissions while async saves run. Show inline progress in the action and preserve entered data on failure.
- Steppers should update immediately and support long-press repeat only after a short hold; announce new value to screen readers.

### 5.4 Sheets and dialogs

- Use one modal layer at a time where possible. Provide a visible drag handle when draggable, a clear title, close/back affordance, and a practical dismiss path.
- Use `DraggableScrollableSheet` only when content benefits from resizing. Coordinate child scroll physics with the sheet so drag transfers naturally from sheet to list.
- Prefer a medium initial detent for secondary details and expand for longer forms; use safe areas and keyboard insets.
- Avoid 350ms elastic entry; settle smoothly with a controlled curve/spring and support a dismiss gesture that tracks the finger.
- Keep destructive confirmation for genuinely irreversible actions; use undo for reversible changes.

### 5.5 Continuous animations

Inventory every `AnimationController.repeat()`. Current recurring candidates include recovery pulse, onboarding tactical radar, tempo pacer waveform/perimeter, and radar draw animations. Classify each:

- **Keep:** motion communicates an active timer/tempo or a clear recovery status that changes meaning.
- **Shorten:** one-time chart reveal when the chart first becomes visible; do not replay on every rebuild/tab visit.
- **Remove:** background scanning, peripheral glow pulse, and looping decoration that does not change user decisions.

Every repeated controller must stop or mute when its route/tab/sheet is invisible and when reduced motion is requested. Avoid starting controllers during a build method.

---

## 6. Phase 5 — Screen-by-screen design implementation

### 6.1 Dashboard (`lib/features/dashboard/screens/dashboard_screen.dart`)

**Goal:** Answer “What should I do today?” at first glance.

- Keep the selected date/date strip compact. Current calendar header consumes substantial first-viewport height; remember the user's collapsed/expanded preference and default to a compact week view after first use.
- Put today's workout and `Start workout` near the top. Keep title, day/session, short exercise preview, and one dominant CTA.
- Place recovery as a concise status with a textual label and explanation; do not rely on a pulsing light or color alone.
- Keep activity cards to the most useful values. Missing sensor data should say why and offer a relevant action, not show generic `Data unavailable` with unexplained empty space.
- Remove duplicate section labels and reduce ornamental borders. Use consistent card gaps and align numeric baselines.
- Confirm the first viewport has no clipped card or CTA at short device heights; use `SliverAppBar`/slivers if the page remains vertically dense.
- Split provider subscriptions as described in §4.2.

### 6.2 Training Splits (`lib/features/workout_builder/screens/workout_builder_screen.dart` and split widgets)

**Goal:** See the active plan, understand today's session, and make a workout with low friction.

- Make the active split the primary card and explain its schedule in concise text.
- Move freestyle workout and “customize routines” into secondary actions; current screen gives several different workflows similar visual weight.
- Remove tactical or inventory metaphors from copy. Use “Training splits,” “Active plan,” “Edit plan,” and “Start workout.”
- Ensure split cards have a single expansion affordance with an adequate touch target and visible expanded state.
- Implement builder drag/reorder with stable keys and clear drag handles. Reorder preview should track the finger and avoid rebuilding the whole screen per move.
- Keep junk-volume warning specific, nonjudgmental, and actionable. Provide an explanation and a way to dismiss/undo changes.
- Eliminate any user-facing “coming soon” placeholder from a primary route; complete the route or hide/remove it until it has useful content.

### 6.3 Exercise Library (`lib/features/exercise_library/screens/exercise_library_screen.dart`)

**Goal:** Find and add an exercise quickly.

- Retain the top-level search and horizontal filter capability. A horizontal chip list should scroll independently without fighting page navigation.
- Reduce row density: exercise name, one compact muscle/equipment subtitle, one clear favorite/add action, and at most one meaningful badge. Put full details on the exercise detail screen.
- Make the whole row open details and keep add as a separate accessible action. Avoid two tiny adjacent targets.
- Use `ListView.builder` with stable keys. Search should be debounced/cancellable, fields normalized once, and result filtering outside `build()`.
- Keep filter and result count in sync. Provide `Clear filters` where filters are active; empty search state should preserve the query and offer a clear action.
- Keep a search clear button with a semantic label and minimum touch size.
- Verify first-scroll raster performance after blur removal and card simplification.

### 6.4 History (`lib/features/history/screens/history_screen.dart`)

**Goal:** Understand training consistency and progress, then act on it.

- For zero sessions, replace the large mostly empty body with a designed empty state: concise explanation, a primary `Start workout` action, and a secondary `Browse training splits` action.
- Keep calendar, lifetime volume, and segments visually distinct but compact. At short heights, calendar should collapse and remain discoverable.
- Use the native segmented-control behavior/semantics where possible. Selected state must not rely only on white fill.
- Charts should have range, unit, and data-summary labels; show what an empty chart needs to become useful.
- Cache chart series by date range/source revision; don't rebuild charts from all workout data during tab animation.
- Calendar date hit targets must remain accessible and not shrink below 44dp if practical; if 7 columns make that impossible on a narrow phone, design an alternate week pager rather than tiny targets.

### 6.5 Account (`lib/features/profile/screens/profile_screen.dart`)

**Goal:** Manage profile and preferences without scrolling friction.

- Fix the confirmed bottom overlap first. Add bottom padding equal to the measured nav pill height + gap + `MediaQuery.paddingOf(context).bottom`; use one shared helper/token from `AppShell` so screens do not drift.
- Verify at max scroll extent that the final setting is fully visible above the pill and can receive a tap.
- Use a compact profile header, then grouped settings sections with rows and dividers. Avoid nested boxed metric tiles when plain aligned values communicate as well.
- Make metric columns responsive: wrap or switch to two columns on narrow widths; don't let rows spill beneath screen edges.
- Use clear labels/values; keep goals and progress explanatory, with units and accessible semantics.
- Avoid placing long user preference summaries in tiny caption text.

### 6.6 Workout session and setup (`lib/features/workout_session/**`)

**Goal:** Log a set one-handed, quickly, and confidently under gym conditions.

- Preserve OLED black, but prioritize legible weight/reps, current set, previous performance, and one dominant `Log set` control.
- Make weight/reps inputs large and easy to adjust. Ensure controls fit on small screens with the keyboard open, in landscape, and at large text scale.
- Keep auto-rest visible but not obstructive. Timer updates should rebuild only the timer/indicator region.
- Remove perimeter pulse/HUD ornament from tempo mode. Make tempo cue and phase clear through text/icon plus a restrained motion trace.
- Provide pause/resume/cancel on animation-like pacers and honor reduced motion. Tempo can still be represented by phase text and haptics when motion is reduced.
- Avoid stacked translucent borders on active cards; the session screen should have fewer visual layers than browsing screens.
- Save set/session state incrementally and restore safely after backgrounding/recreation.

### 6.7 Onboarding and authentication

- Use standard fitness terminology and request only information needed to personalize the plan.
- Keep each screen to one short task, with clear Back/Continue actions, progress that is not overly theatrical, and a skip/guest path where the product supports it.
- Remove simulated “analysis” waits and looping radar sweeps. If recommendation generation is real and asynchronous, show what is happening, make progress honest, and let the user continue/cancel as appropriate.
- Keep keyboard focus, autofill, password manager support, validation, and submit behavior standard.
- Preserve entered values when navigating back or recovering from a validation error.

---

## 7. Phase 6 — Layout that works across devices

### 7.1 Responsive layout rules

- Use `LayoutBuilder`/constraints for layout decisions, not a list of hard-coded device model names.
- On compact phones, keep one column, use responsive horizontal margins, and allow vertical scroll. Avoid fixed heights around text-heavy cards.
- On regular phones, use two columns only for compact metrics with consistent aspect ratios; avoid forcing text into a square.
- On tablets/foldables/wide windows, constrain readable content to a centered max width and optionally use a two-pane master/detail layout. Do not stretch a 400dp list card across an entire tablet.
- Use `MediaQuery.sizeOf(context)`, `paddingOf`, `viewInsetsOf`, and text scaler rather than reading global screen dimensions in leaf widgets.
- Keep safe-area insets for status/navigation bars, cutouts, and keyboard. Test both gesture and three-button Android navigation if available.
- For foldable/tabletop postures, avoid critical buttons under a hinge and keep primary action in the usable pane.
- Support portrait and landscape unless a screen truly requires a single orientation. In landscape, active workout should use available width without shrinking type.

### 7.2 Responsive helpers

Create only useful shared helpers, for example `AppBreakpoints` and a `ResponsiveContent` wrapper:

```dart
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: child,
      ),
    );
  }
}
```

Only add a shared abstraction when it makes behavior consistent. Avoid a generic responsive framework that obscures simple screen layouts.

### 7.3 Accessibility and device settings

- Add semantics to icon-only buttons, selection chips, custom tab items, charts, calendar cells, timers, and steppers (`label`, `value`, `hint`, `selected`, `button`).
- Use focus order matching visual reading order. Ensure screen reader can activate all functionality.
- Test increased contrast, system font scaling, reduced animations, and reduced transparency.
- Do not auto-scroll or animate essential content in a way that causes motion discomfort.
- Avoid tiny low-contrast chart axis labels even if they technically pass contrast; use 11sp minimum and adequate weight.

---

## 8. Phase 7 — Flutter, assets, startup, and memory hygiene

- Keep bundled exercise JSON and fonts/images reasonably sized; remove unreferenced variants after confirming no platform references.
- Lazy-load noncritical image assets and use correctly sized raster assets. Prefer vector/custom-drawn simple icons where appropriate.
- Keep startup path small: initialize Hive/local stores and router first; defer analytics, nonessential chart aggregation, and optional sensor work until needed.
- Do not await network/service initialization before a usable local-first shell unless the app cannot function without it.
- Provide a stable placeholder/skeleton for genuinely asynchronous remote content; avoid a spinner for synchronous Hive reads.
- Check provider keep-alive scope. Permanent app-lifetime providers should be intentional, documented, and bounded in memory.
- Dispose scroll controllers, text controllers, animation controllers, stream subscriptions, and timers.
- Avoid recreating GoRouter or navigation state on each provider notification.
- Avoid synchronous logging/printing during animation or scroll. Use structured debug logging only where needed and remove verbose release logs.
- Run release/profile builds with obfuscation/symbol handling appropriate for the target; optimize assets before enabling aggressive widget caching.
- Ensure local-first paths work without network access and sync indicators reflect actual state.

---

## 9. Implementation sequence and deliverables

Each phase should land as a coherent reviewable change with screenshots and measured evidence. Do not combine every screen rewrite into one large patch.

### Phase A — Baseline + policy reconciliation

Deliver:

- A recorded profile baseline for the scenarios in §4.1.
- A single chosen public app name, recorded in the PR/change notes.
- Updated design guidance that no longer contradicts `AGENTS.md` on copy, text floor, accents, or material use.
- A concrete token table and initial contrast check.

### Phase B — Low-risk, high-impact polish

Deliver:

- Typography tokens switched to Outfit/JetBrains Mono, after visually checking representative dashboard, exercise, history, and session views.
- [x] **Bottom nav insets fixed across all five tabs; Account's final control visible and tappable.** *(Delivered in Chunk 1)*
- History empty state with next actions.
- Reduce redundant chips and borders in Exercise Library and Account.
- Replace visible roleplay wording and remove decorative animation where it does not communicate state.

### Phase C — Navigation and motion

Deliver:

- [x] **Main tab selection changed to tap-based route/indexed stack with zero adjacent screen peeking.** *(Delivered in Chunk 1)*
- [x] **Per-tab scroll state preserved with `PageStorageKey` and independent branches.** *(Delivered in Chunk 1)*
- [x] **Offscreen ticker pause behavior implemented with `TickerMode(enabled: isCurrent)`.** *(Delivered in Chunk 1)*
- [x] **No neighboring page peeks during route change.** *(Delivered in Chunk 1)*

### Phase D — Performance

Deliver:

- Narrow Riverpod subscriptions on Dashboard and other high-frequency views.
- Exercise search debounced and normalized; expensive data work moved out of build.
- Blur restricted to necessary floating layers.
- Chart repaint scope/lazy sliver behavior verified in DevTools.
- Before/after profile numbers from identical scenarios and at least one real Android device.

### Phase E — Cross-device finish

Deliver:

- Compact phone, larger phone, tablet/wide layout, landscape workout, keyboard-open, and 1.5× text scale screenshots.
- Verified 44dp touch targets, safe area, contrast, and screen-reader names/states.
- Reduced transparency and reduced motion verified.
- Regression screenshots for all main tabs and workout logging.

---

## 10. Acceptance checklist for the implementation agent

### Visual and content

- [ ] One canonical app name is used across launch surface, app, exports, and documentation.
- [ ] App uses Outfit for human-facing copy and JetBrains Mono for numeric data only; no pixel-like typeface remains in active screen UI.
- [ ] Cyan has a consistent active/primary meaning; amber has a warning/calendar meaning; other color is restrained and semantic.
- [ ] Common controls use sentence case and direct gym wording.
- [ ] Text never falls below 11sp; secondary text is readable at 4.5:1 contrast on actual surfaces.
- [ ] Cards and controls no longer stack redundant outlines, glows, and blur layers.

### Navigation and motion

- [x] Main tab change does not expose a neighboring screen or block input. *(Delivered in Chunk 1)*
- [x] Rapid tab taps, deep links, back navigation, and state restoration select the correct destination. *(Delivered in Chunk 1)*
- [x] Offscreen tabs do not run decorative tickers or unnecessary rebuilds. *(Delivered in Chunk 1)*
- [ ] Motion is interruptible, brief, and suppressed/reduced under accessibility settings.
- [ ] Pointer-down state is immediate; pointer-up commits; drag-away cancels.

### Layout and accessibility

- [x] Every main tab's last scrollable control clears the floating nav and system safe area. *(Delivered in Chunk 1)*
- [ ] No horizontal overflow or clipped setting at compact width, large text scale, or keyboard-open state.
- [ ] Tablet/wide layout constrains content and uses space intentionally.
- [ ] Icon-only controls, charts, calendar and custom inputs expose useful semantics.
- [ ] Primary touch controls meet 44×44 logical pixels or have an equivalent expanded hit region.

### Performance and stability

- [ ] Profile report includes device, refresh rate, app mode, p50/p95/max UI/raster times, missed frames, and memory observations.
- [ ] First Dashboard-to-tab transition and Exercise Library first scroll meet the agreed target on the reference device.
- [ ] No broad Dashboard rebuild occurs for unrelated single metric updates.
- [ ] Search/filter, chart construction, and workout aggregation do not run synchronously in build/pointer callbacks.
- [ ] Timers remain correct after background/resume, and all controllers/subscriptions are disposed.
- [ ] Before/after screenshots and DevTools captures are attached to the implementation review.

---

## 11. Useful source map

| Concern | Primary code locations |
|---|---|
| Tab shell and horizontal slide | `lib/shared/widgets/app_shell.dart`, `lib/core/router/app_router.dart` |
| Floating nav pill | `lib/shared/widgets/glass_nav_pill.dart` |
| Colors/type/theme | `lib/core/theme/app_colors.dart`, `app_typography.dart`, `app_theme.dart` |
| Shared glass and blur | `lib/shared/widgets/glass_card.dart`, `liquid_glass.dart`, `lib/core/widgets/acrylic_surface.dart` |
| Dashboard and activity subscriptions | `lib/features/dashboard/screens/dashboard_screen.dart`, `models/daily_telemetry_model.dart`, `widgets/*bento_card.dart` |
| Exercise search/list | `lib/features/exercise_library/screens/exercise_library_screen.dart`, `providers/exercise_library_provider.dart`, `widgets/exercise_library_card.dart` |
| Training splits and builder | `lib/features/workout_builder/screens/workout_builder_screen.dart`, `providers/`, `widgets/` |
| History empty state and charts | `lib/features/history/screens/history_screen.dart`, `widgets/sessions_tab_view.dart`, `overload_tab_view.dart`, `muscle_radar_tab_view.dart` |
| Account settings/nav clearance | `lib/features/profile/screens/profile_screen.dart`, `lib/shared/widgets/app_shell.dart` |
| Workout timers and animated session | `lib/features/workout_session/providers/active_session_provider.dart`, `rest_timer_provider.dart`, `tempo_pacer_provider.dart`, `screens/workout_session_screen.dart`, `widgets/tempo_sine_wave_painter.dart`, `tempo_pacer_overlay.dart` |
| Onboarding naming and motion | `lib/features/onboarding/models/onboarding_state.dart`, `providers/onboarding_provider.dart`, `screens/onboarding_screen.dart`, `widgets/tactical_radar_widget.dart` |

## 12. Implementation guardrails

- Preserve existing user data, session recovery, and local-first behavior while changing UI architecture.
- Do not change user-facing branding globally until the name decision is recorded.
- Do not remove a feature solely to improve a screenshot; simplify the information hierarchy while keeping its useful behavior reachable.
- Do not add blur, animation, shadows, or haptics without stating what user task they improve.
- Do not call a screen “done” based only on emulator screenshots. Verify responsive sizes, accessibility scale, and profiler output.
- When updating one of the shared visual tokens, inspect all routes that consume it to avoid unintended cross-screen changes.
- Keep any contrast, motion, layout, and performance regression evidence with the implementation change so another agent can review the result.

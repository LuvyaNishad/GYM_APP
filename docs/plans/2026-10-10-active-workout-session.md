# Active Workout Session Implementation Plan

> **For Agent:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a high-performance, distraction-free Active Workout Session experience with an interactive Sequence Overview (Macro View), Inline Accordion Detailed Set Logger (Micro View), Dual Timer Engine (Elapsed Session Stopwatch + Auto-Rest Countdown with ±10s controls), Dual RIR/RPE effort metrics, and Plate Calculator.

**Architecture:** 
- State management driven by Riverpod (`activeSessionProvider` and `restTimerProvider`) with keep-alive state to survive background navigation.
- Inline progressive disclosure: Exercise sequence cards expand accordion-style directly in-flow, eliminating jarring page transitions.
- Dual-metric synchronization: Simultaneous logging of Reps in Reserve (RIR) and Rate of Perceived Exertion (RPE) with bidirectional computation (`RPE = 10 - RIR`).
- Persistent floating glass Rest Timer pill at screen bottom with auto-start on set completion, pause/resume, ±10s chips, and early skip.

**Tech Stack:** Flutter 3.x, Dart 3.x, Riverpod (State), Hive (Local Persistence), Apple HIG (OLED Black, Min 11pt, Min 4.5:1 contrast, 48x48pt hit targets).

---

### Task 1: Active Session State & Timer Providers (State Layer)

**Files:**
- Create: `lib/features/workout_session/models/active_session_state.dart`
- Create: `lib/features/workout_session/providers/active_session_provider.dart`
- Create: `lib/features/workout_session/providers/rest_timer_provider.dart`
- Test: `test/features/workout_session/active_session_provider_test.dart`

**Step 1: Write the failing tests**
- Test active session initialization with split day and exercises.
- Test elapsed timer tick increments.
- Test logging a set updates completed status and volume.
- Test rest timer countdown, auto-trigger on set check, +10s / -10s adjustments, and early skip.
- Test bidirectional RIR and RPE calculation (`calculateRpeFromRir(2) == 8.0`, `calculateRirFromRpe(9.0) == 1`).

**Step 2: Run test to verify it fails**
- Command: `flutter test test/features/workout_session/active_session_provider_test.dart`
- Expected: FAIL (files and classes not yet defined).

**Step 3: Implement minimal models and providers**
- Implement `ActiveSessionState`, `ActiveWorkoutExercise`, `ActiveWorkoutSet`, and `RestTimerState`.
- Implement `RestTimerNotifier` with periodic tick (`Timer.periodic`), pause, resume, `addSeconds(10)`, `subtractSeconds(10)`, and `skip()`.
- Implement `ActiveSessionNotifier` with `startSession()`, `logSet()`, `addExercise()`, `removeExercise()`, `reorderExercises()`, `expandExercise()`, and `finishSession()`.

**Step 4: Run test to verify it passes**
- Command: `flutter test test/features/workout_session/active_session_provider_test.dart`
- Expected: PASS.

**Step 5: Commit**
- Git commit: `feat(workout_session): add active session and rest timer riverpod state machine`

---

### Task 2: Floating Rest Timer Dock & Session Header Widgets

**Files:**
- Create: `lib/features/workout_session/widgets/active_session_header.dart`
- Create: `lib/features/workout_session/widgets/floating_rest_timer_bar.dart`
- Test: `test/features/workout_session/floating_rest_timer_bar_test.dart`

**Step 1: Write the failing tests**
- Test `ActiveSessionHeader` displays split name, elapsed stopwatch formatted as `HH:MM:SS` or `MM:SS`, set completion progress (e.g. `4 / 16 sets`), and "Finish" action.
- Test `FloatingRestTimerBar` displays remaining countdown (`01:30`), progress bar, `-10s` and `+10s` buttons, pause/resume toggle, and `Skip` button.
- Verify Apple HIG typography floor: every text label ≥ 11.0 pt.

**Step 2: Run test to verify it fails**
- Command: `flutter test test/features/workout_session/floating_rest_timer_bar_test.dart`
- Expected: FAIL.

**Step 3: Implement `ActiveSessionHeader` and `FloatingRestTimerBar`**
- Use `AppColors.surface` with `BackdropFilter` glassmorphism and OLED black background (`#000000`).
- Accent colors: Electric Cyan (`#00E5FF`) for active timer progress and Amber (`#FFB300`) for low-time warning (≤ 15s).
- Ensure buttons have minimum 48×48 pt touch targets.

**Step 4: Run test to verify it passes**
- Command: `flutter test test/features/workout_session/floating_rest_timer_bar_test.dart`
- Expected: PASS.

**Step 5: Commit**
- Git commit: `feat(workout_session): add active session header and floating rest timer bar`

---

### Task 3: Dual RIR/RPE Effort Selector & Plate Calculator Modals

**Files:**
- Create: `lib/features/workout_session/widgets/effort_picker_modal.dart`
- Create: `lib/features/workout_session/widgets/plate_calculator_modal.dart`
- Test: `test/features/workout_session/plate_calculator_test.dart`

**Step 1: Write the failing tests**
- Test plate calculator formula given target weight (e.g., 100 kg on 20 kg barbell = two 20 kg plates per side).
- Test edge cases (target weight less than bar weight, odd weights requiring 1.25 kg plates).
- Test effort selector updates both RIR (0 to 4+) and corresponding RPE (10 to 6).

**Step 2: Run test to verify it fails**
- Command: `flutter test test/features/workout_session/plate_calculator_test.dart`
- Expected: FAIL.

**Step 3: Implement `EffortPickerModal` and `PlateCalculatorModal`**
- `EffortPickerModal`: Clean segmented chips: `[0 RIR / RPE 10 (Failure)]`, `[1 RIR / RPE 9]`, `[2 RIR / RPE 8]`, `[3 RIR / RPE 7]`, `[4+ RIR / RPE ≤6]`, with steppers for fine 0.5 adjustments.
- `PlateCalculatorModal`: Interactive visual diagram showing barbell shaft with color-coded standard Olympic plates per side (25kg red, 20kg blue, 15kg yellow, 10kg green, 5kg white, 2.5kg silver, 1.25kg silver).

**Step 4: Run test to verify it passes**
- Command: `flutter test test/features/workout_session/plate_calculator_test.dart`
- Expected: PASS.

**Step 5: Commit**
- Git commit: `feat(workout_session): add effort picker modal and plate calculator`

---

### Task 4: Detailed Set Logger & Ghost Previous Performance (Micro View)

**Files:**
- Modify/Replace: `lib/features/workout_session/widgets/set_logger_widget.dart`
- Create: `lib/features/workout_session/widgets/exercise_set_table.dart`
- Test: `test/features/workout_session/exercise_set_table_test.dart`

**Step 1: Write the failing tests**
- Test table headers: `SET`, `PREVIOUS`, `KG`, `REPS`, `EFFORT`, `STATUS`.
- Test ghost text displays previous performance (e.g. `80 kg × 8`).
- Test tapping ghost text autofills current weight and reps.
- Test checkmark toggles set completion and triggers auto-rest countdown.
- Test `+ Add Set`, `+ Warmup Set`, and delete set actions.

**Step 2: Run test to verify it fails**
- Command: `flutter test test/features/workout_session/exercise_set_table_test.dart`
- Expected: FAIL.

**Step 3: Implement `ExerciseSetTable`**
- Set index pill (1, 2, 3, or `W` for warmup).
- Ghost previous values in `AppColors.textMuted` (minimum 4.5:1 contrast, `Color(0xFF94A3B8)`).
- Number input fields with increment/decrement steppers and direct numeric keyboard.
- Effort pill showing `2 RIR (8.0)` that opens `EffortPickerModal` on tap.
- Set checkmark button with animated check icon (Cyan glow on complete).

**Step 4: Run test to verify it passes**
- Command: `flutter test test/features/workout_session/exercise_set_table_test.dart`
- Expected: PASS.

**Step 5: Commit**
- Git commit: `feat(workout_session): implement exercise set table with ghost data and set logging`

---

### Task 5: Exercise Sequence List with Inline Accordion Expansion (Macro View)

**Files:**
- Create: `lib/features/workout_session/widgets/exercise_sequence_card.dart`
- Create: `lib/features/workout_session/widgets/exercise_picker_modal.dart`
- Modify: `lib/features/workout_session/screens/workout_session_screen.dart`
- Test: `test/features/workout_session/workout_session_screen_test.dart`

**Step 1: Write the failing tests**
- Test collapsed sequence card renders exercise name, muscle tag, set tally (`2/4 sets completed`), top set (`80 kg × 8`), and expand chevron.
- Test tapping card expands inline accordion to reveal `ExerciseSetTable`.
- Test `+ Add Exercise` button opens `ExercisePickerModal`.
- Test 3-dot popup menu on card for `Replace Exercise`, `Remove Exercise`, `Add Note`.
- Test reordering exercises via drag handles.

**Step 2: Run test to verify it fails**
- Command: `flutter test test/features/workout_session/workout_session_screen_test.dart`
- Expected: FAIL.

**Step 3: Implement `ExerciseSequenceCard`, `ExercisePickerModal`, and wire up `WorkoutSessionScreen`**
- Combine `ActiveSessionHeader`, `ReorderableListView` of `ExerciseSequenceCard`s, and `FloatingRestTimerBar`.
- Implement smooth expansion animation (`AnimatedCrossFade` / `AnimatedSize`) for accordion transitions.
- Support adding and replacing exercises from the local exercise catalog.

**Step 4: Run test to verify it passes**
- Command: `flutter test test/features/workout_session/workout_session_screen_test.dart`
- Expected: PASS.

**Step 5: Commit**
- Git commit: `feat(workout_session): assemble sequence overview with inline accordion logging`

---

### Task 6: Workout Finish Flow & Persistence (Save to Hive)

**Files:**
- Create: `lib/features/workout_session/widgets/workout_summary_dialog.dart`
- Modify: `lib/features/workout_session/providers/active_session_provider.dart`
- Test: `test/features/workout_session/workout_summary_test.dart`

**Step 1: Write the failing tests**
- Test tapping "Finish Workout" shows confirmation summary with elapsed duration, total volume lifted, sets completed, and PR achievements.
- Test confirming saves completed `WorkoutModel` into Hive storage.
- Test updates weekly contribution calendar / heatmap and recovery metrics.

**Step 2: Run test to verify it fails**
- Command: `flutter test test/features/workout_session/workout_summary_test.dart`
- Expected: FAIL.

**Step 3: Implement `WorkoutSummaryDialog` and persistence logic**
- Present visual recap with glassmorphic cards: total volume, duration, completed exercises.
- Save to Hive box, update user state, and navigate back to Dashboard.

**Step 4: Run test to verify it passes**
- Command: `flutter test test/features/workout_session/workout_summary_test.dart`
- Expected: PASS.

**Step 5: Commit**
- Git commit: `feat(workout_session): add workout summary recap and hive persistence`

---

### Task 7: Comprehensive Integration & Live Emulator Verification

**Files:**
- Verify all modified files across `lib/features/workout_session/`.
- Ensure zero analyzer warnings: `flutter analyze`.
- Ensure all test suites pass: `flutter test`.
- Build debug APK and install on emulator `Leon_Pixel_8`.
- Capture screenshot artifacts demonstrating:
  1. Sequence overview with collapsed cards and active exercise highlighted.
  2. Expanded accordion card logging a set with ghost previous data.
  3. Effort picker showing dual RIR & RPE selector.
  4. Floating rest timer active with `-10s` and `+10s` chips.
  5. Barbell plate calculator popover.
  6. Final workout summary modal.

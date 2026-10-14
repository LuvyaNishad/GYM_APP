# LEON — Master Product & Development Roadmap (TODO.md)

> **Purpose:** Master implementation tracker for LEON (Operational Fitness OS). Each task includes concrete architectural steps, files to touch, and test guidelines. Check off (`- [x]`) items as they are completed.

---

## 📋 Epic 1: Goal Accommodation Architecture (Bulk, Cut, Strength, Muscle)

Adapt the app dynamically according to the user's selected primary goal (`BUILD MUSCLE`, `STRENGTH`, `LOSE FAT`, `ATHLETIC`) and target weight set during onboarding.

- [x] **1.1 Dynamic Goal Adaptation State & Service** `[P0]`
  - **Objective:** Create a unified goal adaptation engine that exposes goal-specific metrics, default rest times, target rep ranges, and coaching cues.
  - **How to do it:**
    - Create `lib/features/onboarding/models/training_goal_config.dart` defining `TrainingGoalConfig` (rep ranges, default rest seconds, primary dashboard metric, summary cues).
    - Map `primaryGoal` values:
      - `BUILD MUSCLE`: 8–12 reps, 90–120s rest, Hypertrophy Volume target (10–20 direct sets/week/muscle).
      - `STRENGTH`: 3–6 reps, 180s rest, 1RM PR & peak load tracker.
      - `LOSE FAT`: 8–15 reps, 60–90s rest, Daily Steps (NEAT) & Weight Deficit pace (~0.5 kg/wk).
      - `ATHLETIC`: 5–10 explosive reps, 90s rest, Muscle Balance & Work Capacity.
    - Expose `trainingGoalConfigProvider` in `lib/features/onboarding/providers/onboarding_provider.dart`.

- [x] **1.2 Dynamic Dashboard Bento Metrics** `[P0]`
  - **Objective:** Re-order and customize Dashboard metric cards based on the active training goal.
  - **How to do it:**
    - In `lib/features/dashboard/screens/dashboard_screen.dart` and `daily_workout_bento_card.dart`:
      - If `LOSE FAT`: Elevate Step Count (10,000 steps target) and Calorie Deficit bar. Show Weight Loss progress bar (`Current 78 kg → Goal 74 kg`).
      - If `BUILD MUSCLE`: Display Weekly Hypertrophy Direct Sets (`Chest 14/16`, `Back 12/16 sets`) and Caloric Surplus target.
      - If `STRENGTH`: Display Big 3 / Big 4 Estimated 1RM PR highlights (Squat, Bench, Deadlift, OHP).
      - If `ATHLETIC`: Feature the Muscle Balance Radar and Recovery readiness.

- [x] **1.3 Goal-Aware Rest Timer & Input Hints in Active Workout** `[P0]`
  - **Objective:** Auto-populate workout rest timers and rep placeholders according to goal.
  - **How to do it:**
    - In `lib/features/workout_session/providers/active_session_provider.dart`:
      - Read `trainingGoalConfigProvider` upon `startSession()`.
      - Set default rest timer duration to 180s (Strength), 90s (Muscle/Athletic), or 60s (Fat Loss).
    - In `lib/features/workout_session/widgets/exercise_set_table.dart`:
      - Update rep input placeholder text from generic `8` to goal-specific range (`3-5` for strength, `8-12` for hypertrophy).

- [x] **1.4 Goal-Aware Post-Workout Summary Feedback** `[P1]`
  - **Objective:** Congratulate users with goal-relevant achievements in the workout recap.
  - **How to do it:**
    - In `lib/features/workout_session/widgets/workout_summary_dialog.dart`:
      - If `BUILD MUSCLE`: Calculate and display *"15 effective hypertrophy sets logged for Chest & Delts."*
      - If `STRENGTH`: Highlight PRs and top sets: *"New estimated 1RM Bench: 102.5 kg (+2.5 kg)!"*
      - If `LOSE FAT`: Display density and energy preservation: *"42 mins high-density training. Lean mass stimulus preserved."*

- [x] **1.5 Goal Switching in Profile Settings** `[P1]`
  - **Objective:** Let users change their primary goal anytime without resetting historical workout logs.
  - **How to do it:**
    - In `lib/features/profile/screens/profile_screen.dart`, add a "Training Goal" settings card with a selector modal for the 4 goals.
    - Persist change to Hive `settings_box` and invalidate `trainingGoalConfigProvider`.

---

## 🏋️ Epic 2: Workout-First Active Mode Improvements (instructions.md Phase 1)

Eliminate gym-floor friction, prevent data loss during app interruptions, and provide low-friction set logging.

- [x] **2.1 Active Workout Auto-Resume & Crash Protection** `[P0]`
  - **Objective:** Persist active workout state to Hive after every set change and show a "Resume Workout" banner on app reopen.
  - **How to do it:**
    - In `lib/features/workout_session/providers/active_session_provider.dart`:
      - Add `_persistActiveSession()` to write `session.toJson()` into Hive `active_session_box` whenever sets/exercises mutate.
      - Add `_restoreActiveSession()` on app startup.
      - Clear the box only when "SAVE WORKOUT" or "DISCARD" is explicitly confirmed.
    - In `lib/features/dashboard/screens/dashboard_screen.dart`:
      - If `activeSession.isActive == true`, render an animated sticky banner: *"WORKOUT IN PROGRESS: Bench Press (Set 2/4) — RESUME"*.
      - Tapping resumes `WorkoutSessionScreen` instantly.

- [x] **2.2 1-Tap Ghost Data Auto-Fill** `[P1]`
  - **Objective:** Tapping the previous session's ghost reference instantly populates weight and reps for the current set.
  - **How to do it:**
    - In `lib/features/workout_session/widgets/exercise_set_table.dart`:
      - Wrap ghost text widget (`80 kg × 8`) in an `InkWell`.
      - On tap, trigger `notifier.updateWeight(setIndex, prevWeight)` and `notifier.updateReps(setIndex, prevReps)`.
      - Trigger light haptic click (`HapticFeedback.selectionClick()`).

- [x] **2.3 In-Workout Exercise Substitution Modal** `[P0]`
  - **Objective:** When gym equipment is taken, allow 1-tap substitution with a matching exercise without losing completed workout sets.
  - **How to do it:**
    - Add a "Substitute" action button on `ExerciseSequenceCard` menu (`lib/features/workout_session/widgets/exercise_sequence_card.dart`).
    - Open `ExerciseSubstitutionSheet`:
      - Query `ExerciseLibrary` for exercises matching the same primary muscle group and available equipment.
      - Display alternatives (e.g. *Barbell Bench Press $\rightarrow$ Dumbbell Bench Press, Machine Chest Press*).
    - In `ActiveSessionNotifier`: add `substituteExercise(String oldId, Exercise newExercise)` which replaces the remaining uncompleted sets while preserving logged data.

- [x] **2.4 Tactile Set Checkmark Feedback & Micro-Celebration** `[P1]`
  - **Objective:** Provide instant, crisp physical confirmation when completing a set.
  - **How to do it:**
    - In `lib/features/workout_session/widgets/exercise_set_table.dart`:
      - Call `HapticFeedback.mediumImpact()` when tapping set checkmark.
      - Add a 180ms scale/bounce animation on the checkmark icon when transitioning from outline to solid cyan.

- [x] **2.5 Background Rest Timer Notifications & Audio/Vibration Alerts** `[P1]`
  - **Objective:** Notify user when rest time expires even if the screen is locked or music app is open.
  - **How to do it:**
    - Integrate `flutter_local_notifications` for foreground/background alerts.
    - When rest timer reaches 0:
      - Fire local notification: *"Rest complete! Next set: Bench Press (Set 3)"*.
      - Trigger distinctive triple vibration (`HapticFeedback.vibrate()`).
    - Add user toggle in Settings to enable/disable sound chime or keep it vibration-only for headphones.

---

## 📚 Epic 3: Routines & Exercise Discovery (instructions.md Phase 2)

Empower lifters to explore exercises, understand form, and build custom multi-week routines.

- [x] **3.1 Full Exercise Detail & Form Guide Screen** `[P1]`
  - **Objective:** Dedicated screen showing anatomical muscle highlights, step-by-step form cues, common pitfalls, and exercise PR history.
  - **How to do it:**
    - Create `lib/features/exercise_library/screens/exercise_detail_screen.dart`.
    - Route: `/exercise/:id` in `app_router.dart`.
    - Content sections:
      - Animated demonstration placeholder / vector visual.
      - Target Muscles: Primary (e.g., Pectoralis Major) & Secondary (Triceps, Anterior Deltoid).
      - Setup & Execution: Step 1, 2, 3 bullet points with bold keywords.
      - Common Mistakes & Safety Tips (e.g., *"Don't flare elbows past 75°"*).
      - History Tab: Personal bests (1RM, Max Volume, Max Reps) and line chart.
      - CTA: *"Add to Today's Workout"* or *"Add to Routine"*.

- [x] **3.2 Custom Routine Library & Template Builder** `[P1]`
  - **Objective:** Allow users to create, clone, edit, and organize multiple saved workout routines (e.g., PPL, Upper/Lower, 5/3/1).
  - **How to do it:**
    - Create `lib/features/workout_builder/screens/routine_library_screen.dart`.
    - Features:
      - Tab for "Preset Splits" vs. "My Custom Routines".
      - "Create New Routine" floating action button.
      - Exercise selector with multi-select and drag-to-reorder (`ReorderableListView`).
      - Routine metadata: Name, targeted muscle focus, estimated duration, days per week.
      - Persist user routines to Hive `custom_routines_box`.

---

## 📈 Epic 4: Understandable Analytics & Progress (instructions.md Phase 3)

Provide transparent, evidence-informed progress metrics without misleading fitness claims.

- [x] **4.1 Scientific 1RM Progression Line Charts** `[P1]`
  - **Objective:** Track true strength progression over time for major compound exercises.
  - **How to do it:**
    - Implement the standard Epley formula in `lib/core/utils/strength_math.dart`:
      $$\text{1RM} = \text{weight} \times \left(1 + \frac{\text{reps}}{30}\right)$$
    - In `lib/features/history/widgets/exercise_progress_chart.dart` / `overload_tab_view.dart`:
      - Plot estimated 1RM over time using `fl_chart`.
      - Clearly state the formula in a caption footnote per `instructions.md`.
      - Filter by time ranges: 1M, 3M, 6M, 1Y, All.

- [x] **4.2 Interactive Calendar Workout Log & Historical Editor** `[P1]`
  - **Objective:** View past workout logs by date and allow retroactive edits for mistakes.
  - **How to do it:**
    - In `lib/features/history/screens/history_screen.dart`:
      - Add a collapsible month calendar widget. Days with completed workouts show cyan indicator dots.
      - Tapping a day displays the workout log card (Exercises, Sets, Weights, Reps, RPE, Duration).
      - Add an "Edit Workout" button that opens the session in an edit modal to fix typos or missing sets safely.

- [x] **4.3 Explainable Metrics & Science Tooltips** `[P2]`
  - **Objective:** Explain calculation origins for Muscle Radar and ECG Recovery scores.
  - **How to do it:**
    - Add an info icon (`Icons.info_outline`, size 16) beside:
      - Muscle Balance Radar $\rightarrow$ Dialog: *"Calculated from total direct sets completed across Push, Pull, and Leg muscle groups over the past 7 days."*
      - ECG Recovery Score $\rightarrow$ Dialog: *"Self-reported readiness estimate based on workout frequency, rest intervals, and logged sleep/hydration. Not a medical evaluation."*

---

## 🤝 Epic 5: Sustainable Consistency & Habits (instructions.md Phase 4 & 5)

Encourage consistent long-term training habits without shame mechanics or burnout.

- [x] **5.1 No-Shame Weekly Consistency Widget** `[P1]`
  - **Objective:** Replace fragile daily streak counters with a supportive weekly consistency tracker.
  - **How to do it:**
    - In `lib/features/dashboard/widgets/weekly_consistency_card.dart` & `dashboard_screen.dart`:
      - Display: `3 of 4 planned workouts completed this week (75%)`.
      - Rolling 4-week compliance ring or bar chart.
      - Supportive neutral messaging for missed days per `instructions.md` Section 1 ("Life happens. Resume when ready.").

- [x] **5.2 Recomposition & Body Measurement Tracker** `[P2]`
  - **Objective:** Track body measurements (waist, arms, chest) and body fat % alongside weight.
  - **How to do it:**
    - Expand `lib/features/health_tracking/screens/health_tracking_screen.dart`:
      - Add "Measurements" tab: Waist, Arms, Chest, Thighs.
      - Progress comparison: Delta over 30 days (`-2.0 cm waist`, `+1.0 cm arm`).
      - Local encrypted storage for progress metrics.

- [x] **5.3 Offline-First Synchronization Status Indicator** `[P2]`
  - **Objective:** Clearly display local data safety state.
  - **How to do it:**
    - Add a subtle status dot in the App Bar:
      - Green: *"Saved Locally & Synced"*.
      - Amber: *"Saved Locally (Offline — Will Sync When Connected)"*.
    - Guarantees zero data loss as required by `instructions.md` Section 10.

---

## 🧪 Epic 6: Test Suite & Code Quality Gates

Maintain rigorous test coverage and zero static analysis warnings throughout all additions.

- [x] **6.1 Unit & Widget Tests for Dynamic Goals** `[P0]`
  - Tested that selecting `BUILD MUSCLE`, `STRENGTH`, `LOSE FAT`, and `ATHLETIC` assigns goal-specific rest timers, rep placeholders, and reactive provider configurations.
  - Test suites: `test/features/onboarding/training_goal_config_test.dart` and `test/features/workout_session/active_session_provider_test.dart`.
- [x] **6.2 Session Persistence & Auto-Resume Tests** `[P0]`
  - Verified active workout serialization to Hive, JSON roundtripping, auto-restore on launch, and sticky dashboard banner visibility.
  - Test suites: `test/features/workout_session/active_session_provider_test.dart` and `test/features/workout_session/epic2_active_mode_test.dart`.
- [x] **6.3 Exercise Substitution Flow Tests** `[P1]`
  - Tested that substituting an exercise swaps uncompleted sets while preserving previously logged sets and updates active session state.
  - Test suites: `test/features/workout_session/epic2_active_mode_test.dart` and `test/features/workout_session/active_session_provider_test.dart`.
- [x] **6.4 Apple HIG Compliance Check** `[P0]`
  - Verified that all UI widgets strictly enforce minimum $\ge 11.0$ pt font size, contrast $\ge 4.5:1$ WCAG AA, and standard gym terminology across all screens.
  - Test suite: `test/core/apple_hig_compliance_test.dart` and static analysis `flutter analyze lib test` (0 issues).

---

## 🎯 Implementation Roadmap (Recommended Order)

1. **Sprint 1 (Immediate):**
   - Epic 1: Goal Accommodation Engine (1.1, 1.2, 1.3)
   - Epic 2: Active Workout Crash Recovery & 1-Tap Ghost Autofill (2.1, 2.2)
2. **Sprint 2:**
   - Epic 2: In-Workout Exercise Substitution (2.3) & Background Rest Timer (2.5)
   - Epic 4: 1RM Progression & History Calendar Editor (4.1, 4.2)
3. **Sprint 3:**
   - Epic 3: Full Exercise Detail Form Guide (3.1) & Custom Routine Builder (3.2)
   - Epic 5: Weekly Consistency (5.1) & Recomposition Tracking (5.2)

# LEON — Master Product & Development Roadmap (TODO.md)

> **Purpose:** Master implementation roadmap for LEON (Operational Fitness OS). Tracks active production milestones, pending user feedback/holds, and planned epics to bring the app from a local-first power tracker to a commercial-grade, multi-device fitness platform. Check off (`- [x]`) items as they are completed.

---

## 🚀 Active Production Backlog (Remaining Tasks)

### ⏱️ Active Feedback & Biomechanical Enhancements `[Next Up / Immediate]`
Items surfaced directly from user feedback, UX refinements, and gym biomechanics testing:

- [x] **0.1 Exercise-Aware Phase Cadences & Timespans** `[P0 - Complete]`
  - **Objective:** Move beyond static `3-0-1-0` presets by dynamically tailoring phase durations to exercise biomechanics.
  - **Logic:**
    - Heavy Compounds (Squat, Bench Press, Romanian Deadlift): `3-1-1-0` (3s controlled descent, 1s stable pause, 1s explosive drive).
    - Explosive Lifts (Power Clean, Snatch, Push Press): `1-0-1-0` (Fast reposition, explosive concentric drive).
    - Hypertrophy Isolations (Bicep Curls, Lateral Raises, Leg Extensions): `2-1-2-1` or `3-0-2-1` (Strict peak contraction hold and controlled eccentric).
  - **Files:** `lib/features/workout_session/providers/tempo_pacer_provider.dart`, `lib/features/workout_session/models/tempo_pacer_state.dart`, `lib/features/workout_session/widgets/tempo_sine_wave_painter.dart`

- [x] **0.2 Automated Rest Transition on Tempo Set Completion** `[P1 - Complete]`
  - **Objective:** Seamlessly transition to the floating rest timer bar the instant the target rep count is reached during tempo pacing or when tapping "FINISH SET & REST".
  - **Files:** `lib/features/workout_session/providers/tempo_pacer_provider.dart`, `lib/features/workout_session/widgets/tempo_pacer_overlay.dart`

- [x] **0.3 Barbell Warmup Pyramid Set Calculator** `[P1 - Complete]`
  - **Objective:** Inside the Barbell Plate Calculator modal, added "WARMUP PYRAMID" segmented tab that auto-computes optimal ramp-up sets for the active working weight.
  - **Progression:** Empty Bar (20kg × 10) $\rightarrow$ 50% (5×) $\rightarrow$ 70% (3×) $\rightarrow$ 85% (1×) $\rightarrow$ 100% Working Set with colored Olympic bumper plate chips and 1-tap "LOAD" button.
  - **Files:** `lib/features/workout_session/widgets/plate_calculator_modal.dart`

- [x] **0.4 Exercise-Specific Default Rest Timers** `[P2 - Complete]`
  - **Objective:** Auto-set rest duration when loading exercises into active workout and exercise catalog:
    - Heavy Compounds: 180s (3:00)
    - Moderate Compounds: 120s (2:00)
    - Accessories & Isolations: 60s–90s
  - **Files:** `lib/features/exercise_library/models/exercise_library_item.dart`, `lib/features/workout_session/widgets/exercise_picker_modal.dart`, `lib/features/workout_builder/models/split_model.dart`

- [x] **0.5 Superset & Giant Set Grouping** `[P2 - Complete]`
  - **Objective:** Ability to link exercises as antagonistic supersets (e.g., Incline Dumbbell Press + Chest-Supported Row) in Workout Builder and Active Session Screen with alternating set execution and linked Cyan bracket UI.
  - **Files:** `lib/features/workout_builder/models/split_model.dart`, `lib/features/workout_session/providers/active_session_provider.dart`, `lib/features/workout_session/widgets/exercise_sequence_card.dart`, `lib/features/workout_session/screens/workout_session_screen.dart`

---

### ☁️ Epic 1: Cloud Sync & Multi-Device Backup `[P0]`
Enable seamless cloud authentication and background synchronization so users can switch phones or access workouts across multiple devices without data loss.

- [ ] **1.1 Cloud Authentication Provider (Apple ID & Google Sign-In)** `[P0]`
  - **Objective:** Provide frictionless 1-tap sign-in while preserving anonymous guest-mode autonomy.
  - **How to do it:**
    - Create `lib/features/authentication/services/auth_service.dart` integrating OAuth (Apple & Google).
    - Allow immediate guest bypass; prompt cloud backup linking in the Account Profile screen.
    - Persist user ID and auth token in secure storage (`flutter_secure_storage`).
  - **Files:** `lib/features/authentication/`, `lib/features/profile/screens/profile_screen.dart`

- [ ] **1.2 Bidirectional Cloud Sync Engine (Hive ↔ Remote Backend)** `[P0]`
  - **Objective:** Synchronize workouts, custom routines, body measurements, and profile biometrics to remote database (Supabase / Firebase Firestore).
  - **How to do it:**
    - Create `lib/services/sync_service.dart` with an offline change queue (`sync_queue_box`).
    - Every local mutation generates a tombstone or timestamped event (`last_modified_utc`).
    - Resolve conflicts using client-wins or last-write-wins timestamp heuristics.
    - Update `SyncStatusIndicator` in app bar: Green (Synced), Amber (Syncing / Offline changes pending), Red (Sync error).
  - **Files:** `lib/services/sync_service.dart`, `lib/shared/widgets/sync_status_indicator.dart`

---

### 🔊 Epic 3: Rest Timer Audio Sound Pack & Headphone Ducking `[P1]`
Provide crystal-clear auditory cues that play through gym headphones without disrupting music playback.

- [ ] **3.1 Audio Asset Sound Pack Integration** `[P1]`
  - **Objective:** Bundle low-latency audio sound cues for rest interval countdown (3, 2, 1, chime) and tempo metronome clicks.
  - **How to do it:**
    - Add crisp audio assets to `assets/audio/`:
      - `rest_countdown_beep.wav`
      - `rest_complete_chime.wav`
      - `metronome_woodblock.wav`
      - `boxing_bell_round.wav`
    - Use `audioplayers` with `AudioContext` set to duck background audio (`duckOthers: true`).
    - Add setting toggle in Profile screen: `Sound Alerts: [Sound + Vibrate / Vibrate Only / Silent]`.
  - **Files:** `lib/features/workout_session/providers/rest_timer_provider.dart`, `lib/features/profile/`

---

### 🥗 Epic 4: Nutrition & Macro Tracking System `[P1]`
Elevate the daily Bento Grid from basic calorie/water counters to an intelligent macronutrient tracking powerhouse.

- [ ] **4.1 Macronutrient Breakdown Engine (Protein, Carbs, Fats)** `[P1]`
  - **Objective:** Track daily macronutrient grams and compare against goal-calculated targets.
  - **How to do it:**
    - In `lib/features/health_tracking/models/nutrition_log_model.dart`, define daily macro entries.
    - In Dashboard Bento Grid, expand `CaloriesBentoCard` to show horizontal segmented macro distribution bar (`P: 180g / C: 220g / F: 65g`).
    - Auto-calculate macro targets based on user's goal (`BULKING` = 2.0g/kg protein, `CUTTING` = 2.4g/kg protein).
  - **Files:** `lib/features/health_tracking/`, `lib/features/dashboard/widgets/`

- [ ] **4.2 Barcode Food Scanner (OpenFoodFacts API)** `[P2]`
  - **Objective:** 1-tap camera barcode scanning to fetch nutrition facts instantly.
  - **How to do it:**
    - Integrate `mobile_scanner` package for instant camera barcode reading.
    - Query free `world.openfoodfacts.org` REST API to fetch calories and macros.
    - Render quick-confirm modal: portion size, logged meal (Breakfast, Lunch, Dinner, Snack).
  - **Files:** `lib/features/health_tracking/screens/barcode_scanner_screen.dart`

---

### ⌚ Epic 5: Smartwatch Companion App (Wear OS & watchOS) `[P2]`
Allow lifters to leave their phone on the gym bench and track sets directly from their wrist.

- [ ] **5.1 Wear OS Standalone / Companion App** `[P2]`
  - **Objective:** Wrist-based set logging, weight/rep incrementors, and vibration on rest expiry.
  - **How to do it:**
    - Build Flutter Wear OS module or native Kotlin Wear OS app communicating via Wearable Data Layer API.
    - Stream active exercise, set checkoff, and real-time heart rate sensor data back to LEON mobile.
  - **Files:** `android/wear/`

- [ ] **5.2 Apple Watch watchOS Companion** `[P2]`
  - **Objective:** Swift WatchKit companion app communicating via `WatchConnectivity`.
  - **How to do it:**
    - Set logging view with Digital Crown scroll for weight adjustment.
    - Taptic Engine rest completion alerts.
  - **Files:** `ios/WatchApp/`

---

### 📸 Epic 6: Social Workout Brag Cards (Story Exporter) `[P2]`
Allow users to share high-contrast, aesthetic workout recaps to Instagram Stories, Twitter, and WhatsApp.

- [ ] **6.1 9:16 High-Res Story Image Generator** `[P2]`
  - **Objective:** Generate a minimalist, cyberpunk-styled 1080×1920 image from completed workout data.
  - **How to do it:**
    - Wrap summary canvas in a `RepaintBoundary` with Noguchi Onyx background, glowing cyan accents, total tonnage, personal records (PRs), workout duration, and 6-axis Muscle Balance Radar.
    - Convert boundary to PNG bytes and launch native share sheet using `share_plus`.
  - **Files:** `lib/features/workout_session/widgets/workout_share_card.dart`

---

## 🏛️ Completed Milestones (Archived Log)

All items below have been implemented, verified on Android emulator, HIG-validated, and pushed to `main`:

- [x] **Buttery-Smooth VSync Hardware Stopwatch Motion:** Upgraded `_BiomechanicalWavePainter` to calculate exact sub-millisecond progress on display VSync using hardware `Stopwatch`, eliminating periodic timer jitter.
- [x] **Decluttered Kinetic Dot:** Removed trailing tooltip text pill from the kinetic orb, keeping the luminous core, aura, and radar ripple ring clean and unobscured.
- [x] **Seamless OLED HUD & Dynamic Rep-Expansion Glow:** Removed rigid box borders around the wave graph, extended the HUD flush to the screen base, and added a progressive Electric Cyan $\rightarrow$ Pure White perimeter glow that pulsates and expands as reps advance.
- [x] **Exercise-Aware Starting Phase:** Biomechanical detection to begin with concentric lift (`↑ DRIVE`) for bottom-start exercises (Deadlift, Barbell Row, Pull-ups) and eccentric descent (`↓ LOWER`) for top-start exercises (Squat, Bench Press, Shoulder Press).
- [x] **Two-Line Cadence Header:** Split the tempo dropdown selector into an uncluttered 2-line title and numbers layout (`CONTROL` / `3 0 1`).
- [x] **Android Foreground Service Persistent Notification:** Notification drawer workout persistence with live countdown and `+30s`/`Skip Rest` actions.
- [x] **iOS Live Activity & Dynamic Island Widget:** ActivityKit widget with compact Dynamic Island pill and lock screen banner.
- [x] **Goal Accommodation Architecture:** Dynamic goal engine (`BULKING`, `CUTTING`, `STRENGTH`, `MAINTENANCE`, `RECOMPOSITION`), 7-screen survey, goal-specific rep ranges, rest timers, and coaching cues.
- [x] **Active Workout Crash Recovery & Auto-Resume:** Persistent Hive DB session storage, automatic state restoration on launch, sticky resume trigger on `DailyWorkoutBentoCard`.
- [x] **1-Tap Previous Workout Ghost Data Auto-Fill:** Quick-fill weight/reps with haptic feedback.
- [x] **In-Workout Exercise Substitution Sheet:** 1-tap exercise swap with agonist muscle matching while preserving completed sets.
- [x] **Visual Barbell Plate Calculator:** Barbell sleeve graphic calculating Olympic 25kg/20kg/15kg/10kg/5kg/2.5kg/1.25kg plate distribution.
- [x] **Dual Effort Picker:** Seamless switching between RIR (Reps in Reserve) and RPE (Rate of Perceived Exertion) with exertion color coding.
- [x] **Scientific 1RM Progression & Epley Formula:** Automated 1RM calculation with interactive `fl_chart` curves and time range filters (1M, 3M, 6M, 1Y, ALL).
- [x] **Interactive Collapsible Calendar & History Editor:** Collapsible 1-week strip / 6-row month calendar, 1-workout-per-day enforcement, color-coded days, and retroactive workout log editor modal.
- [x] **Custom Routine Library & Template Builder:** Full multi-split creator, routine duplicator, drag-and-drop exercise reordering, and routine folders.
- [x] **Full Exercise Detail & Form Guides:** 150+ exercises with anatomy tags, step-by-step cues, common mistakes, and interactive 1RM calculator.
- [x] **Restored 2×2 Dashboard Bento Grid:** Clean, equal-sized square cards (Steps, Calories, Water, Sleep) with quick-increment dialogs.
- [x] **Collapsed Available Splits:** Available splits start collapsed by default for zero visual clutter.
- [x] **Body Measurements & Recomposition Tracker:** Log waist, chest, arms, thighs, and body fat % with 30-day delta indicators.
- [x] **1-Page Athletic PDF Report Exporter:** Complete vector PDF report summarizing lift volume, PRs, and body metrics.
- [x] **Apple HIG Strict Compliance:** Minimum 11.0 pt typography floor, $\ge 4.5:1$ contrast ratio, 2-accent color discipline (Electric Cyan `#00E5FF` & Amber `#FFB300`), and zero pseudo-military roleplay terms.

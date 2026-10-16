# LEON — Master Product Roadmap (TODO.md)

> **Purpose:** Active production backlog and remaining feature epics for LEON (Premium Minimalist Fitness OS). All completed milestones and shipped features have been pruned to keep this backlog actionable and uncluttered.

---

## 🚀 Active Production Backlog (Pending Tasks)

### ☁️ Epic 1: Cloud Sync & Multi-Device Backup `[P0]`
Enable seamless cloud authentication and background synchronization so users can switch phones or access workouts across multiple devices without data loss.

- [ ] **1.1 Cloud Authentication Provider (Apple ID & Google Sign-In)** `[P0]`
  - **Objective:** Provide frictionless 1-tap sign-in while preserving anonymous guest-mode autonomy.
  - **Implementation:**
    - Create `lib/features/authentication/services/auth_service.dart` integrating OAuth (Apple & Google).
    - Allow immediate guest bypass; prompt cloud backup linking in the Account Profile screen.
    - Persist user ID and auth token in secure storage (`flutter_secure_storage`).
  - **Files:** `lib/features/authentication/`, `lib/features/profile/screens/profile_screen.dart`

- [ ] **1.2 Bidirectional Cloud Sync Engine (Hive ↔ Remote Backend)** `[P0]`
  - **Objective:** Synchronize workouts, custom routines, body measurements, and profile biometrics to remote database (Supabase / Firebase Firestore).
  - **Implementation:**
    - Create `lib/services/sync_service.dart` with an offline change queue (`sync_queue_box`).
    - Every local mutation generates a tombstone or timestamped event (`last_modified_utc`).
    - Resolve conflicts using client-wins or last-write-wins timestamp heuristics.
    - Update `SyncStatusIndicator` in app bar: Green (Synced), Amber (Syncing / Offline changes pending), Red (Sync error).
  - **Files:** `lib/services/sync_service.dart`, `lib/shared/widgets/sync_status_indicator.dart`

---

### 🔊 Epic 2: Rest Timer Audio Sound Pack & Headphone Ducking `[P1]`
Provide crystal-clear auditory cues that play through gym headphones without disrupting music playback.

- [ ] **2.1 Audio Asset Sound Pack Integration** `[P1]`
  - **Objective:** Bundle low-latency audio sound cues for rest interval countdown (3, 2, 1, chime) and tempo metronome clicks.
  - **Implementation:**
    - Add crisp audio assets to `assets/audio/`:
      - `rest_countdown_beep.wav`
      - `rest_complete_chime.wav`
      - `metronome_woodblock.wav`
      - `boxing_bell_round.wav`
    - Use `audioplayers` with `AudioContext` set to duck background audio (`duckOthers: true`).
    - Add setting toggle in Profile screen: `Sound Alerts: [Sound + Vibrate / Vibrate Only / Silent]`.
  - **Files:** `lib/features/workout_session/providers/rest_timer_provider.dart`, `lib/features/profile/`

---

### 🥗 Epic 3: Nutrition & Macro Tracking System `[P1]`
Elevate the daily Bento Grid from basic calorie/water counters to an intelligent macronutrient tracking powerhouse.

- [ ] **3.1 Macronutrient Breakdown Engine (Protein, Carbs, Fats)** `[P1]`
  - **Objective:** Track daily macronutrient grams and compare against goal-calculated targets.
  - **Implementation:**
    - In `lib/features/health_tracking/models/nutrition_log_model.dart`, define daily macro entries.
    - In Dashboard Bento Grid, expand `CaloriesBentoCard` to show horizontal segmented macro distribution bar (`P: 180g / C: 220g / F: 65g`).
    - Auto-calculate macro targets based on user's goal (`BULKING` = 2.0g/kg protein, `CUTTING` = 2.4g/kg protein).
  - **Files:** `lib/features/health_tracking/`, `lib/features/dashboard/widgets/`

- [ ] **3.2 Barcode Food Scanner (OpenFoodFacts API)** `[P2]`
  - **Objective:** 1-tap camera barcode scanning to fetch nutrition facts instantly.
  - **Implementation:**
    - Integrate `mobile_scanner` package for instant camera barcode reading.
    - Query free `world.openfoodfacts.org` REST API to fetch calories and macros.
    - Render quick-confirm modal: portion size, logged meal (Breakfast, Lunch, Dinner, Snack).
  - **Files:** `lib/features/health_tracking/screens/barcode_scanner_screen.dart`

---

### ⌚ Epic 4: Smartwatch Companion App (Wear OS & watchOS) `[P2]`
Allow lifters to leave their phone on the gym bench and track sets directly from their wrist.

- [ ] **4.1 Wear OS Standalone / Companion App** `[P2]`
  - **Objective:** Wrist-based set logging, weight/rep incrementors, and vibration on rest expiry.
  - **Implementation:**
    - Build Flutter Wear OS module or native Kotlin Wear OS app communicating via Wearable Data Layer API.
    - Stream active exercise, set checkoff, and real-time heart rate sensor data back to LEON mobile.
  - **Files:** `android/wear/`

- [ ] **4.2 Apple Watch watchOS Companion** `[P2]`
  - **Objective:** Swift WatchKit companion app communicating via `WatchConnectivity`.
  - **Implementation:**
    - Set logging view with Digital Crown scroll for weight adjustment.
    - Taptic Engine rest completion alerts.
  - **Files:** `ios/WatchApp/`

---

### 📸 Epic 5: Social Workout Brag Cards (Story Exporter) `[P2]`
Allow users to share high-contrast, aesthetic workout recaps to Instagram Stories, Twitter, and WhatsApp.

- [ ] **5.1 9:16 High-Res Story Image Generator** `[P2]`
  - **Objective:** Generate a minimalist, high-contrast 1080×1920 image from completed workout data.
  - **Implementation:**
    - Wrap summary canvas in a `RepaintBoundary` with Noguchi Onyx background, glowing cyan accents, total tonnage, personal records (PRs), workout duration, and 6-axis Muscle Balance Radar.
    - Convert boundary to PNG bytes and launch native share sheet using `share_plus`.
  - **Files:** `lib/features/workout_session/widgets/workout_share_card.dart`

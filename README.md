# LEON

A Flutter fitness tracker with local workout storage, editable training routines, and workout history.

## Features

- Routine creation, exercise reordering, and training split selection.
- Training pauses with an optional return date; resume from the last logged matching workout.
- A 231-exercise catalog with search, filters, form instructions, and alternatives.
- Active workout logging with warmups, RPE, unilateral sets, draft recovery, rest timers, and a plate calculator.
- Workout history, estimated one-rep-max trends, PRs, and muscle coverage charts.
- Manual water, sleep, and active-calorie logs.
- Optional read-only Health Connect / Apple Health imports for steps, heart rate, sleep and active calories; manual logs take precedence and overlapping sources are not added.
- Daily phone steps, including Realme/OPlus daily totals/history on supported phones and a sensor fallback.

## Development

Install Flutter/Dart compatible with `pubspec.yaml`, the Android SDK for Android builds, and Python 3 for the repository guard. Android builds require Android 8.0 or later; Health Connect requires a supported Android 9+ device and an available Health Connect provider. Apple Health requires the Runner HealthKit entitlement and a matching signing profile; validate iOS builds on macOS. On Windows, enable Developer Mode for plugin symlinks. iOS builds require macOS and Xcode.

From the project directory:

```sh
flutter pub get
```

After changing generated models:

```sh
dart run build_runner build --force-jit
```

Verify code and tests:

```sh
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
```

If the shared Flutter test runner reports incomplete files, run each file in an isolated process:

```sh
python tool/run_tests.py
```

The runner saves logs under `build/test_runs`, retries runner-only load failures once, and exits unsuccessfully for any failing file. Optional test-file paths restrict the run.

For an Android build/install, select a device from `flutter devices`:

```sh
flutter build apk --debug
flutter install -d <device-id>
```

## Android release builds

Android uses the application ID `app.leon.fitness`. Release builds require a permanent signing key and never fall back to debug signing. Create a keystore with `keytool`, keep it and its passwords backed up securely, and configure `.local/release-signing.properties`:

```properties
storeFile=../.local/leon-release.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=leon
keyPassword=YOUR_KEY_PASSWORD
```

Paths are relative to the `android` directory. Keystores and signing properties stay outside Git. Use the same application ID and signing key for every update, and increase the build number in `pubspec.yaml` for each distribution.

```sh
flutter build apk --release --no-pub
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`. Install updates over the existing app; uninstalling clears local data. The earlier `com.example.leon` development install is a separate app: use LEON's JSON export/import to transfer its data to the release package.

## Accounts and cloud sync

LEON supports Google sign-in, email/password accounts with email confirmation, and immediate guest use. Local data and pending changes are isolated by account. Cloud saves include workouts, routines, profile/preferences, measurements, custom exercises, favorites and dated habits/steps. Active drafts, live timers and hardware sensor baselines stay local. Conflicting edits are retained for review in Account → Cloud & Sync.

Guest data remains on the device while offline. When connected, a guest can receive an anonymous cloud identity; link Google or export a JSON backup for recovery after uninstall. Recovery requires completed cloud saves. Signing in to an existing account restores its data before offering to import guest records.

For a Supabase deployment, configure the project URL and publishable key in `lib/core/config/supabase_config.dart` and apply the SQL in `supabase/migrations` in order. The `cloud_records` table is the app's complete sync store; older normalized tables remain for compatibility. Client writes use the owner-checked `apply_cloud_changes` function with revisions and durable retry receipts.

Enable email, Google, anonymous sign-ins and manual identity linking in Supabase Authentication. Create a Google **Web application** OAuth client with `https://<project-ref>.supabase.co/auth/v1/callback` as its authorized redirect URI, and enter its client ID and secret in Supabase's Google provider settings. The client secret belongs only in Supabase. Add `app.leon.fitness://login-callback/` to Supabase's allowed redirect URLs. While Google's consent screen is in Testing, add permitted Google accounts under Test users. Android and iOS callback schemes are included in the app projects.

## Repository hygiene

Keep internal planning, progress reports, design notes, logs, and agent configuration local. Public documentation stays in this README and the platform README. Build configuration such as `CMakeLists.txt` remains tracked.

Enable the repository push hook after cloning:

```sh
git config --local core.hooksPath tool/hooks
python tool/check_private_files.py
```

The guard rejects private documents in tracked files and outgoing commits, including files added and subsequently deleted before a push. Do not force-add ignored notes or bypass the hook. Real credentials stay outside Git; only `.env.example` is tracked.

If a Git client uses a different Python environment, set `git config --local leon.privateFilesPython <absolute-python-executable>` to select its Python 3 interpreter.

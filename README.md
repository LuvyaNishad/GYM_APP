# LEON

A Flutter fitness tracker with local workout storage, editable training routines, and workout history.

## Features

- Routine creation, exercise reordering, and training split selection.
- Training pauses with an optional return date; resume from the last logged matching workout.
- A 231-exercise catalog with search, filters, form instructions, and alternatives.
- Active workout logging with warmups, RPE, unilateral sets, draft recovery, rest timers, and a plate calculator.
- Workout history, estimated one-rep-max trends, PRs, and muscle coverage charts.
- Manual water, sleep, and active-calorie logs.
- Daily phone steps, including Realme/OPlus daily totals/history on supported phones and a sensor fallback.

## Development

Install Flutter/Dart compatible with `pubspec.yaml`, the Android SDK for Android builds, and Python 3 for the repository guard. On Windows, enable Developer Mode for plugin symlinks. iOS builds require macOS and Xcode.

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

For an Android build/install, select a device from `flutter devices`:

```sh
flutter build apk --debug
flutter install -d <device-id>
```

## Repository hygiene

Keep internal planning, progress reports, design notes, logs, and agent configuration local. Public documentation stays in this README and the platform README. Build configuration such as `CMakeLists.txt` remains tracked.

Enable the repository push hook after cloning:

```sh
git config --local core.hooksPath tool/hooks
python tool/check_private_files.py
```

The guard rejects private documents in tracked files and outgoing commits, including files added and subsequently deleted before a push. Do not force-add ignored notes or bypass the hook. Real credentials stay outside Git; only `.env.example` is tracked.

If a Git client uses a different Python environment, set `git config --local leon.privateFilesPython <absolute-python-executable>` to select its Python 3 interpreter.

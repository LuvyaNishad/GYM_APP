# Running LEON

How to get LEON running on your Windows machine using Antigravity, Claude Code, and Android
Studio. Each tool has one job:

| Tool | Its job here |
|---|---|
| **Android Studio** | Provides the Android SDK and a device to run on (emulator or a plugged-in phone). You don't have to write code in it. |
| **Antigravity / Claude Code** | Your editor + terminal. This is where you edit files and run the `flutter` commands below. |
| **Flutter CLI** | The bridge. It compiles the app and installs it onto whatever device Android Studio provides. |

The mental model: Android Studio *hosts the device*, Flutter *builds and deploys to it*, and your
editor is just where you type. They connect through the Flutter CLI — every tool talks to `flutter`
on the command line, not to each other directly.

---

## One-time setup

### 1. Enable Windows Developer Mode  ⚠️ required

Flutter plugins need symlink support on Windows. Without this, `flutter run` fails. Open the
settings page and turn Developer Mode on:

```bash
start ms-settings:developers
```

### 2. Install the Flutter SDK

If `flutter --version` errors, install it: https://docs.flutter.dev/get-started/install/windows
Then confirm the toolchain:

```bash
flutter doctor
```

Fix anything with a red ✗. The lines that matter for this project are **Flutter**, **Android
toolchain**, and **Android Studio**. You can ignore the Chrome/Edge web lines and the Visual Studio
(Windows desktop) line — LEON targets Android.

### 3. Android Studio: SDK + a device

Install Android Studio (https://developer.android.com/studio), open it once, and let it finish
downloading the Android SDK. Then get a device to run on — pick one:

- **Emulator:** Android Studio → **Device Manager** (phone icon in the toolbar) → **Create Device**
  → pick e.g. *Pixel 7*, a recent system image (API 34+), Finish. Press ▶ to boot it.
- **Physical phone:** enable **Developer options** → **USB debugging** on the phone, plug it in over
  USB, tap **Allow** on the debugging prompt.

Confirm your editor's terminal can see the device:

```bash
flutter devices
```

You should see your emulator or phone listed. If it's empty, the device isn't booted / plugged in.

---

## Every-run steps

Run these from the project root (`leon/`) in the Antigravity or Claude Code terminal.

```bash
# 1. Secrets file — copy the template, fill in Supabase keys (or leave the
#    placeholders; cloud sync is deferred, the app runs local-first without them).
cp .env.example .env

# 2. Fetch dependencies
flutter pub get

# 3. Generate the Freezed / JSON code (models won't compile without this)
dart run build_runner build --force-jit

# 4. Launch on the connected device
flutter run
```

While `flutter run` is live: press `r` for hot reload, `R` for hot restart, `q` to quit.

---

## Gotchas specific to this project

- **Use `--force-jit` for codegen.** The plain `dart run build_runner build` tries an AOT snapshot
  step that fails on `objective_c`'s native build hook. `--force-jit` skips it. There is **no**
  `--delete-conflicting-outputs` flag anymore — don't add it.
- **Use `dart analyze`, not `flutter analyze`.** `flutter analyze` crashes on this toolchain with
  *"analysis server exited with code 64."* `dart analyze` works. A clean run reports **2 issues,
  0 errors** (two harmless `prefer_final_fields` infos).
- **Re-run codegen after editing any model** in `lib/models/` or any `@freezed` class. If you see
  errors about a missing `_$Something` or `.g.dart`, that's the fix.
- **Never commit `.env`.** Only `.env.example` belongs in git. Your real Supabase keys stay local.

---

## Running from Android Studio instead (optional)

If you'd rather press a green ▶ than type `flutter run`: open the `leon/` folder in Android Studio
(it detects Flutter via `pubspec.yaml`), pick your device in the top toolbar dropdown, and hit Run.
You still need to run `dart run build_runner build --force-jit` in a terminal at least once first.
Editing continues in Antigravity / Claude Code — Android Studio just needs to be open to host the
emulator.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/app_providers.dart';

enum WorkoutCue { countdown, complete, metronome, bell }

enum WorkoutAlertMode { soundAndVibrate, vibrateOnly, silent }

class WorkoutCueService {
  WorkoutCueService({this.channel = const MethodChannel('leon/cues')}) {
    if (supported) {
      channel.setMethodCallHandler((call) async {
        if (call.method == 'interrupted') onInterrupted?.call();
      });
    }
  }
  void Function()? onInterrupted;
  final MethodChannel channel;
  bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  Future<void> play(
    WorkoutCue cue, {
    required bool sound,
    required bool vibrate,
  }) async {
    if (!sound && !vibrate) return;
    if (!supported) return;
    try {
      await channel.invokeMethod<void>('play', {
        'cue': cue.name,
        'sound': sound,
        'vibrate': vibrate,
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<void> stop() async {
    if (!supported) return;
    try {
      await channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}

final workoutCueServiceProvider = Provider((ref) => WorkoutCueService());

/// All workout feedback reads the canonical Account preferences at cue time.
Future<void> playWorkoutCue(
  Ref ref,
  WorkoutCue cue, {
  bool sound = true,
  bool vibrate = true,
}) {
  final profile = ref.read(userProfileProvider);
  return ref
      .read(workoutCueServiceProvider)
      .play(
        cue,
        sound: sound && (profile?.audioCuesEnabled ?? true),
        vibrate: vibrate && (profile?.hapticFeedbackEnabled ?? true),
      );
}

final workoutAlertModeProvider = Provider((ref) {
  final user = ref.watch(userProfileProvider);
  if (user?.audioCuesEnabled ?? true) return WorkoutAlertMode.soundAndVibrate;
  return (user?.hapticFeedbackEnabled ?? true)
      ? WorkoutAlertMode.vibrateOnly
      : WorkoutAlertMode.silent;
});

class WorkoutFeedback {
  const WorkoutFeedback(this.service, this.sound, this.vibrate);
  final WorkoutCueService service;
  final bool sound, vibrate;
  Future<void> play(WorkoutCue cue, {bool sound = true, bool vibrate = true}) =>
      service.play(
        cue,
        sound: sound && this.sound,
        vibrate: vibrate && this.vibrate,
      );
}

final workoutFeedbackProvider = Provider((ref) {
  final user = ref.watch(userProfileProvider);
  return WorkoutFeedback(
    ref.watch(workoutCueServiceProvider),
    user?.audioCuesEnabled ?? true,
    user?.hapticFeedbackEnabled ?? true,
  );
});

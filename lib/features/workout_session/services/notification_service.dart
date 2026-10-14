import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

/// Notification identifiers.
abstract class WorkoutNotificationIds {
  static const int restTimer = 1001;
  static const int restCompletedAlert = 1002;
  static const int activeWorkout = 1003;
}

/// Service managing Android Persistent Foreground Notifications and background alerts.
class WorkoutNotificationService {
  WorkoutNotificationService() {
    _initPlugin();
  }

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Callback for interactive notification buttons (+30s, Skip Rest).
  void Function(String actionId)? onActionTapped;

  Future<void> _initPlugin() async {
    if (kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    try {
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final actionId = response.actionId;
          if (actionId != null && onActionTapped != null) {
            onActionTapped!(actionId);
          }
        },
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('[WorkoutNotificationService] Error initializing notifications: $e');
    }
  }

  /// Request permissions on Android 13+ and iOS.
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidImplementation =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final iosImplementation =
          _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// Shows or updates the ongoing persistent rest countdown notification.
  Future<void> showRestTimerNotification({
    required String exerciseName,
    required int setNumber,
    required int remainingSeconds,
    required int totalDurationSeconds,
  }) async {
    if (!_isInitialized || kIsWeb) return;

    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final formattedTime =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final androidDetails = AndroidNotificationDetails(
      'leon_workout_rest',
      'Active Rest Timer',
      channelDescription: 'Persistent countdown and controls for rest intervals',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      ongoing: true,
      autoCancel: false,
      color: AppColors.primary,
      colorized: true,
      category: AndroidNotificationCategory.stopwatch,
      showProgress: true,
      maxProgress: totalDurationSeconds > 0 ? totalDurationSeconds : 90,
      progress: remainingSeconds,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'add_30',
          '+30s',
          showsUserInterface: false,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          'skip_rest',
          'Skip Rest',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _plugin.show(
        WorkoutNotificationIds.restTimer,
        'REST TIMER • $formattedTime',
        'Next: $exerciseName (Set $setNumber)',
        notificationDetails,
      );
    } catch (e) {
      debugPrint('[WorkoutNotificationService] Error showing rest notification: $e');
    }
  }

  /// Fires a high-priority vibration and sound alert when a rest interval finishes.
  Future<void> showRestCompletedNotification({
    required String exerciseName,
    required int nextSetNumber,
  }) async {
    if (!_isInitialized || kIsWeb) return;

    // First dismiss ongoing rest progress bar
    await cancelRestNotification();

    final androidDetails = AndroidNotificationDetails(
      'leon_rest_alerts',
      'Rest Interval Alerts',
      channelDescription: 'Vibration and alert when rest interval completes',
      importance: Importance.high,
      priority: Priority.high,
      color: AppColors.primary,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
      category: AndroidNotificationCategory.alarm,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _plugin.show(
        WorkoutNotificationIds.restCompletedAlert,
        'REST COMPLETE ⚡',
        'Time for Set $nextSetNumber of $exerciseName',
        notificationDetails,
      );
    } catch (e) {
      debugPrint('[WorkoutNotificationService] Error showing completion notification: $e');
    }
  }

  /// Cancels the persistent rest notification.
  Future<void> cancelRestNotification() async {
    if (!_isInitialized || kIsWeb) return;
    try {
      await _plugin.cancel(WorkoutNotificationIds.restTimer);
    } catch (e) {
      debugPrint('[WorkoutNotificationService] Error canceling rest notification: $e');
    }
  }

  /// Shows or updates the persistent notification when the app is minimized with an active workout.
  Future<void> showActiveWorkoutNotification({
    required String splitName,
    required String currentExerciseName,
    required int currentSet,
    required int totalSets,
    double? weightKg,
    int? reps,
  }) async {
    if (!_isInitialized || kIsWeb) return;

    final weightRepsText = (weightKg != null && reps != null)
        ? ' • ${weightKg.toStringAsFixed(1)} kg × $reps'
        : '';

    final androidDetails = AndroidNotificationDetails(
      'leon_active_workout',
      'Active Workout Session',
      channelDescription: 'Persistent status bar indicator while workout is in progress',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      ongoing: true,
      autoCancel: false,
      color: AppColors.primary,
      colorized: true,
      category: AndroidNotificationCategory.workout,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'open_workout',
          'Resume Workout',
          showsUserInterface: true,
          cancelNotification: false,
        ),
      ],
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _plugin.show(
        WorkoutNotificationIds.activeWorkout,
        'WORKOUT IN PROGRESS: ${splitName.toUpperCase()}',
        '$currentExerciseName (Set $currentSet/$totalSets)$weightRepsText',
        notificationDetails,
      );
    } catch (e) {
      debugPrint('[WorkoutNotificationService] Error showing active workout notification: $e');
    }
  }

  /// Cancels the active workout notification.
  Future<void> cancelActiveWorkoutNotification() async {
    if (!_isInitialized || kIsWeb) return;
    try {
      await _plugin.cancel(WorkoutNotificationIds.activeWorkout);
    } catch (e) {
      debugPrint('[WorkoutNotificationService] Error canceling active workout notification: $e');
    }
  }

  /// Cancels all LEON workout notifications.
  Future<void> cancelAll() async {
    if (!_isInitialized || kIsWeb) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('[WorkoutNotificationService] Error canceling all notifications: $e');
    }
  }
}

final workoutNotificationServiceProvider = Provider<WorkoutNotificationService>((ref) {
  final service = WorkoutNotificationService();
  return service;
});

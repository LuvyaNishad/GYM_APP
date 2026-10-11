import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/features/dashboard/providers/dashboard_provider.dart';
import 'package:leon/features/history/providers/history_provider.dart';
import 'package:leon/models/workout_model.dart';

void main() {
  group('History & Calendar Sync Tests', () {
    test('SelectedCalendarDate.select is idempotent and does not flip-flop', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(selectedCalendarDateProvider.notifier);
      final testDate = DateTime(2026, 10, 8);

      // Initial state is null
      expect(container.read(selectedCalendarDateProvider), isNull);

      // First click: selects testDate
      notifier.select(testDate);
      expect(container.read(selectedCalendarDateProvider), testDate);

      // Second click on the same date: retains testDate (does NOT toggle to null)
      notifier.select(testDate);
      expect(container.read(selectedCalendarDateProvider), testDate);

      // Third click on the same date: still retains testDate
      notifier.select(testDate);
      expect(container.read(selectedCalendarDateProvider), testDate);

      // Clear explicitly clears back to null
      notifier.clear();
      expect(container.read(selectedCalendarDateProvider), isNull);
    });

    test('historyWorkoutsProvider strictly enforces 1 workout per calendar day', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workouts = container.read(historyWorkoutsProvider);
      expect(workouts, isNotEmpty);

      // Verify no two workouts share the exact same calendar day
      final seenDays = <String>{};
      for (final w in workouts) {
        final key = '${w.date.year}-${w.date.month}-${w.date.day}';
        expect(
          seenDays.contains(key),
          isFalse,
          reason: 'Duplicate workout found for calendar day: $key',
        );
        seenDays.add(key);
      }
    });

    test('loggedWorkoutDatesProvider matches historyWorkoutsProvider dates 1:1', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workouts = container.read(historyWorkoutsProvider);
      final loggedDates = container.read(loggedWorkoutDatesProvider);

      // Every logged date MUST have an actual workout
      for (final loggedDate in loggedDates) {
        final matching = workouts.where(
          (w) =>
              w.date.year == loggedDate.year &&
              w.date.month == loggedDate.month &&
              w.date.day == loggedDate.day,
        );
        expect(
          matching.length,
          equals(1),
          reason: 'Logged green date $loggedDate must have exactly 1 workout',
        );
      }

      // Every workout in history MUST be present in loggedWorkoutDatesProvider
      for (final w in workouts) {
        final hasDate = loggedDates.any(
          (d) =>
              d.year == w.date.year &&
              d.month == w.date.month &&
              d.day == w.date.day,
        );
        expect(
          hasDate,
          isTrue,
          reason: 'Workout date ${w.date} must be present in loggedWorkoutDates',
        );
      }
    });

    test('Filtering by a red (missed/rest) day yields 0 workouts', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workouts = container.read(historyWorkoutsProvider);
      final loggedDates = container.read(loggedWorkoutDatesProvider);

      // Find a past date that is NOT in loggedDates (a rest or missed day)
      final now = DateTime.now();
      DateTime? nonWorkoutDate;
      for (int i = 1; i <= 30; i++) {
        final candidate = now.subtract(Duration(days: i));
        final isLogged = loggedDates.any(
          (d) =>
              d.year == candidate.year &&
              d.month == candidate.month &&
              d.day == candidate.day,
        );
        if (!isLogged) {
          nonWorkoutDate = DateTime(candidate.year, candidate.month, candidate.day);
          break;
        }
      }

      expect(nonWorkoutDate, isNotNull);

      // When filtered by this non-workout date, zero workouts should be found
      final filtered = workouts.where(
        (w) =>
            w.date.year == nonWorkoutDate!.year &&
            w.date.month == nonWorkoutDate.month &&
            w.date.day == nonWorkoutDate.day,
      );
      expect(filtered.isEmpty, isTrue);
    });

    test('Filtering by a green (worked out) day yields exactly 1 workout', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workouts = container.read(historyWorkoutsProvider);
      final loggedDates = container.read(loggedWorkoutDatesProvider);

      expect(loggedDates, isNotEmpty);
      final firstGreenDate = loggedDates.first;

      final filtered = workouts.where(
        (w) =>
            w.date.year == firstGreenDate.year &&
            w.date.month == firstGreenDate.month &&
            w.date.day == firstGreenDate.day,
      );
      expect(filtered.length, equals(1));
    });
  });
}

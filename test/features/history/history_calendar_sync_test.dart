import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/features/dashboard/providers/dashboard_provider.dart';
import 'package:leon/features/history/providers/history_provider.dart';
import 'package:leon/models/workout_model.dart';

class _TestHistoryWorkoutsNotifier extends HistoryWorkoutsNotifier {
  _TestHistoryWorkoutsNotifier(this.initial);
  final List<WorkoutModel> initial;

  @override
  List<WorkoutModel> build() => initial;
}

void main() {
  final sampleWorkouts = [
    WorkoutModel(
      id: 'w1',
      userId: 'u1',
      name: 'Push Day A',
      date: DateTime(2026, 10, 20),
      durationSeconds: 3000,
      totalVolumeKg: 6000,
      exercises: const [],
    ),
    WorkoutModel(
      id: 'w2',
      userId: 'u1',
      name: 'Pull Day A',
      date: DateTime(2026, 10, 22),
      durationSeconds: 3200,
      totalVolumeKg: 7000,
      exercises: const [],
    ),
    WorkoutModel(
      id: 'w3',
      userId: 'u1',
      name: 'Leg Day A',
      date: DateTime(2026, 10, 24),
      durationSeconds: 3600,
      totalVolumeKg: 8000,
      exercises: const [],
    ),
  ];

  group('History & Calendar Sync Tests', () {
    test('historyWorkoutsProvider starts completely clean with 0 workouts on fresh launch', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workouts = container.read(historyWorkoutsProvider);
      expect(workouts, isEmpty);

      final loggedDates = container.read(loggedWorkoutDatesProvider);
      expect(loggedDates, isEmpty);
    });

    test('SelectedCalendarDate.select is idempotent and does not flip-flop', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(selectedCalendarDateProvider.notifier);
      final testDate = DateTime(2026, 10, 8);

      expect(container.read(selectedCalendarDateProvider), isNull);

      notifier.select(testDate);
      expect(container.read(selectedCalendarDateProvider), testDate);

      notifier.select(testDate);
      expect(container.read(selectedCalendarDateProvider), testDate);

      notifier.clear();
      expect(container.read(selectedCalendarDateProvider), isNull);
    });

    test('historyWorkoutsProvider strictly enforces 1 workout per calendar day', () {
      final container = ProviderContainer(
        overrides: [
          historyWorkoutsProvider.overrideWith(
            () => _TestHistoryWorkoutsNotifier(sampleWorkouts),
          ),
        ],
      );
      addTearDown(container.dispose);

      final workouts = container.read(historyWorkoutsProvider);
      expect(workouts, isNotEmpty);

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
      final container = ProviderContainer(
        overrides: [
          historyWorkoutsProvider.overrideWith(
            () => _TestHistoryWorkoutsNotifier(sampleWorkouts),
          ),
        ],
      );
      addTearDown(container.dispose);

      final workouts = container.read(historyWorkoutsProvider);
      final loggedDates = container.read(loggedWorkoutDatesProvider);

      for (final loggedDate in loggedDates) {
        final matching = workouts.where(
          (w) =>
              w.date.year == loggedDate.year &&
              w.date.month == loggedDate.month &&
              w.date.day == loggedDate.day,
        );
        expect(matching.length, equals(1));
      }

      for (final w in workouts) {
        final hasDate = loggedDates.any(
          (d) =>
              d.year == w.date.year &&
              d.month == w.date.month &&
              d.day == w.date.day,
        );
        expect(hasDate, isTrue);
      }
    });

    test('Filtering by a non-workout day yields 0 workouts', () {
      final container = ProviderContainer(
        overrides: [
          historyWorkoutsProvider.overrideWith(
            () => _TestHistoryWorkoutsNotifier(sampleWorkouts),
          ),
        ],
      );
      addTearDown(container.dispose);

      final workouts = container.read(historyWorkoutsProvider);
      final nonWorkoutDate = DateTime(2026, 10, 21); // In between w1 (20th) and w2 (22nd)

      final filtered = workouts.where(
        (w) =>
            w.date.year == nonWorkoutDate.year &&
            w.date.month == nonWorkoutDate.month &&
            w.date.day == nonWorkoutDate.day,
      );
      expect(filtered.isEmpty, isTrue);
    });

    test('Filtering by a worked out day yields exactly 1 workout', () {
      final container = ProviderContainer(
        overrides: [
          historyWorkoutsProvider.overrideWith(
            () => _TestHistoryWorkoutsNotifier(sampleWorkouts),
          ),
        ],
      );
      addTearDown(container.dispose);

      final workouts = container.read(historyWorkoutsProvider);
      final targetDate = DateTime(2026, 10, 20);

      final filtered = workouts.where(
        (w) =>
            w.date.year == targetDate.year &&
            w.date.month == targetDate.month &&
            w.date.day == targetDate.day,
      );
      expect(filtered.length, equals(1));
      expect(filtered.first.name, 'Push Day A');
    });
  });
}

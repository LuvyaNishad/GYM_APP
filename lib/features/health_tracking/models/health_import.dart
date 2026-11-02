enum HealthMetric { steps, heartRate, sleep, activeCalories }

enum HealthAvailability { ready, installRequired, unsupported, error }

enum HealthAccess { granted, denied, unknown }

enum HealthReadState { data, noData, denied, error, disabled, unavailable }

extension HealthMetricLabel on HealthMetric {
  String get label => switch (this) {
    HealthMetric.steps => 'Steps',
    HealthMetric.heartRate => 'Heart rate',
    HealthMetric.sleep => 'Sleep',
    HealthMetric.activeCalories => 'Active calories',
  };
}

/// Calendar constructors preserve local midnight/noon across DST changes.
class HealthWindow {
  const HealthWindow(this.start, this.end);
  factory HealthWindow.forMetric(
    HealthMetric metric,
    DateTime now, {
    DateTime Function(int year, int month, int day, int hour)? calendar,
  }) {
    final date =
        calendar ?? (int y, int m, int d, int h) => DateTime(y, m, d, h);
    final midnight = date(now.year, now.month, now.day, 0);
    if (metric != HealthMetric.sleep) return HealthWindow(midnight, now);
    final noon = date(now.year, now.month, now.day, 12);
    return HealthWindow(
      date(now.year, now.month, now.day - 1, 12),
      now.isBefore(noon) ? now : noon,
    );
  }
  final DateTime start, end;
}

class HealthReading {
  const HealthReading({
    required this.state,
    this.access = HealthAccess.unknown,
    this.value,
    this.sources = const [],
    this.platform = 'Health platform',
    this.sampleAt,
    this.method,
    this.window,
  });
  final HealthReadState state;
  final HealthAccess access;
  final num? value;
  final List<String> sources;
  final String platform;
  final DateTime? sampleAt;
  final String? method;
  final HealthWindow? window;
  String get statusLabel => switch (state) {
    HealthReadState.data =>
      access == HealthAccess.unknown
          ? 'Readable data; access private'
          : 'Read access allowed',
    HealthReadState.noData =>
      access == HealthAccess.unknown
          ? 'No readable data; check Apple Health access'
          : 'No records in this window',
    HealthReadState.denied => 'Read permission needed',
    HealthReadState.error => 'Could not refresh; try again',
    HealthReadState.disabled => 'Import off',
    HealthReadState.unavailable => 'Health platform unavailable',
  };
}

class HealthImport {
  const HealthImport({
    required this.day,
    required this.availability,
    this.readings = const {},
    this.refreshedAt,
  });
  final DateTime day;
  final HealthAvailability availability;
  final Map<HealthMetric, HealthReading> readings;
  final DateTime? refreshedAt;
  HealthReading reading(HealthMetric metric) =>
      readings[metric] ?? const HealthReading(state: HealthReadState.disabled);
}

/// Union sleep intervals, excluding overlaps between stages or devices.
double sleepIntervalHours(List<HealthWindow> intervals, HealthWindow window) {
  final clipped =
      intervals
          .map(
            (i) => HealthWindow(
              i.start.isBefore(window.start) ? window.start : i.start,
              i.end.isAfter(window.end) ? window.end : i.end,
            ),
          )
          .where((i) => i.end.isAfter(i.start))
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
  DateTime? start, end;
  var milliseconds = 0;
  for (final interval in clipped) {
    if (end == null || interval.start.isAfter(end)) {
      if (start != null) milliseconds += end!.difference(start).inMilliseconds;
      start = interval.start;
      end = interval.end;
    } else if (interval.end.isAfter(end)) {
      end = interval.end;
    }
  }
  if (start != null) milliseconds += end!.difference(start).inMilliseconds;
  return milliseconds / Duration.millisecondsPerHour;
}

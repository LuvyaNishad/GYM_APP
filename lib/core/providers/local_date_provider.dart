import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One date boundary for Home selection, rotation and weekly comparisons.
final localDateProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final timer = Timer(
    DateTime(now.year, now.month, now.day + 1).difference(now),
    ref.invalidateSelf,
  );
  ref.onDispose(timer.cancel);
  return today;
});

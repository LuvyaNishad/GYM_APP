import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder workout session provider — whether a session is active.
/// TODO: implement active session timer, set logging, and rest timer.
///
/// Kept alive so an in-progress session survives navigation away from the
/// session screen.
class SessionNotifier extends Notifier<bool> {
  @override
  bool build() {
    ref.keepAlive();
    return false;
  }

  void start() => state = true;

  void end() => state = false;
}

final sessionProvider =
    NotifierProvider<SessionNotifier, bool>(SessionNotifier.new);

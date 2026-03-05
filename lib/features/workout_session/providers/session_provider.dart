import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder workout session provider.
/// TODO: implement active session timer, set logging, and rest timer.
final sessionProvider = StateProvider<bool>((ref) => false); // isSessionActive

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder recovery provider.
/// TODO: implement soreness, sleep score, and HRV state.
final recoveryProvider = StateProvider<int>((ref) => 100); // recovery % 0-100

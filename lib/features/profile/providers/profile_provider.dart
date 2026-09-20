import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder profile provider.
/// TODO: implement user settings and stats state.
class ProfileNotifier extends Notifier<Map<String, dynamic>> {
  @override
  Map<String, dynamic> build() => const {};
}

final profileProvider =
    NotifierProvider<ProfileNotifier, Map<String, dynamic>>(
  ProfileNotifier.new,
);

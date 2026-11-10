import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/auth_link_service.dart';
import '../../../services/supabase_service.dart';

final authLinkServiceProvider = Provider<AuthLinkService>(
  (ref) => SupabaseService.authLinks,
);

class AuthLinkNotifier extends Notifier<AuthLinkState> {
  @override
  AuthLinkState build() {
    final service = ref.watch(authLinkServiceProvider);
    final subscription = service.changes.listen((next) {
      if (ref.mounted) state = next;
    });
    ref.onDispose(() => unawaited(subscription.cancel()));
    return service.state;
  }

  Future<void> updatePassword(String password) =>
      ref.read(authLinkServiceProvider).updatePassword(password);
  Future<void> leave() => ref.read(authLinkServiceProvider).leave();
}

final authLinkProvider = NotifierProvider<AuthLinkNotifier, AuthLinkState>(
  AuthLinkNotifier.new,
);

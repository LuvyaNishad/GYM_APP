import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:leon/features/authentication/providers/auth_provider.dart';
import 'package:leon/services/auth_service.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/services/supabase_service.dart';
import '../../helpers/memory_hive_service.dart';

class FakeAuth extends AuthService {
  FakeAuth() : super(SupabaseService());
  final events = StreamController<sb.AuthState>.broadcast();
  sb.Session? session;
  bool confirmationRequired = true;
  int calls = 0;
  final user = sb.User(
    id: '11111111-1111-4111-8111-111111111111',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-11-05T00:00:00Z',
  );
  @override
  Stream<sb.AuthState> get changes => events.stream;
  @override
  bool get isAuthenticated => session != null;
  @override
  bool get isAnonymous => false;
  @override
  String? get currentUserId => session?.user.id;
  @override
  String? get currentUserEmail => session?.user.email;
  @override
  Future<sb.AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    calls++;
    return sb.AuthResponse(user: user);
  }

  @override
  Future<sb.AuthResponse> signInWithEmail(String email, String password) async {
    calls++;
    return sb.AuthResponse(user: user, session: session);
  }

  @override
  Future<bool> signInWithGoogle({bool useExistingAccount = false}) async {
    calls++;
    return true;
  }

  @override
  Future<void> signOut() async {
    session = null;
    events.add(sb.AuthState(sb.AuthChangeEvent.signedOut, null));
  }
}

void main() {
  late FakeAuth auth;
  late ProviderContainer container;
  setUp(() {
    auth = FakeAuth();
    container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        hiveServiceProvider.overrideWithValue(MemoryHiveService()),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await auth.events.close();
  });
  test(
    'unconfirmed signup stays unauthenticated with persistent confirmation guidance',
    () async {
      await container
          .read(authProvider.notifier)
          .signUp('test@example.invalid', 'password', 'Test');
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.userId, isNull);
      expect(state.message, contains('confirm'));
      expect(state.isLoading, isFalse);
    },
  );
  test('a user object without a session cannot complete login', () async {
    await expectLater(
      container
          .read(authProvider.notifier)
          .signIn('test@example.invalid', 'password'),
      throwsStateError,
    );
    expect(container.read(authProvider).status, AuthStatus.unauthenticated);
    expect(container.read(authProvider).error, contains('session'));
  });
  test(
    'OAuth launch is not treated as authenticated and can be retried after cancellation',
    () async {
      final notifier = container.read(authProvider.notifier);
      await notifier.signInWithGoogle();
      expect(container.read(authProvider).status, AuthStatus.unauthenticated);
      expect(container.read(authProvider).message, contains('browser'));
      await notifier.signInWithGoogle();
      expect(auth.calls, 2);
    },
  );
  test(
    'external auth events update state and sign-out clears identity',
    () async {
      container.read(authProvider);
      auth.session = sb.Session(
        accessToken: 'synthetic',
        tokenType: 'bearer',
        user: auth.user,
      );
      auth.events.add(sb.AuthState(sb.AuthChangeEvent.signedIn, auth.session));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(authProvider).userId, auth.user.id);
      await auth.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(authProvider).userId, isNull);
      expect(container.read(authProvider).status, AuthStatus.unauthenticated);
    },
  );
  test(
    'guest use does not wait for network or create a false authenticated identity',
    () async {
      await container.read(authProvider.notifier).signInAsGuest();
      expect(auth.calls, 0);
      expect(container.read(authProvider).status, AuthStatus.unauthenticated);
    },
  );
}

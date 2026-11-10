import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:leon/services/auth_link_service.dart';
import 'package:leon/services/auth_service.dart';
import 'package:leon/services/supabase_service.dart';

const recoveryOwner = '11111111-1111-4111-8111-111111111111';
final recoveryUser = User(
  id: recoveryOwner,
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  email: 'lifter@example.invalid',
  createdAt: '2026-11-10T00:00:00Z',
);

class _SupabaseStub extends SupabaseService {
  _SupabaseStub(this.testClient);
  final SupabaseClient testClient;
  @override
  SupabaseClient get client => testClient;
  @override
  User? get currentUser => testClient.auth.currentUser;
}

class _EmailAuth extends AuthService {
  _EmailAuth(super.service);
  @override
  Future<void> prepareSignIn() async {}
}

class _PkceStorage extends GotrueAsyncStorage {
  final values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}

void main() {
  late SupabaseClient client;
  late AuthLinkService links;
  String? marker;
  late List<http.Request> requests;
  bool failPassword = false, failClear = false;
  Completer<void>? updateGate;

  Future<void> openRecovery() async {
    final callback = Uri.parse(
      '${AuthService.callbackUrl}#access_token=synthetic&refresh_token=refresh&token_type=bearer&expires_in=3600&type=recovery',
    );
    expect(links.inspectCallback(callback), isTrue);
    await client.auth.getSessionFromUrl(callback);
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() {
    marker = null;
    failPassword = false;
    failClear = false;
    updateGate = null;
    requests = [];
    client = SupabaseClient(
      'https://test.invalid',
      'synthetic-publishable-key',
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.method == 'PUT' && request.url.path.endsWith('/user')) {
          await updateGate?.future;
          if (failPassword) {
            return http.Response(
              '{"code":"weak_password","msg":"weak"}',
              422,
              headers: {'x-supabase-api-version': '2024-01-01'},
            );
          }
          return http.Response(jsonEncode(recoveryUser.toJson()), 200);
        }
        if (request.method == 'GET' && request.url.path.endsWith('/user')) {
          return http.Response(jsonEncode(recoveryUser.toJson()), 200);
        }
        if (request.url.path.endsWith('/logout')) return http.Response('', 204);
        return http.Response('{}', 200);
      }),
    );
    links = AuthLinkService(
      readRecoveryOwner: () => marker,
      writeRecoveryOwner: (owner) async {
        if (owner == null && failClear) throw StateError('disk unavailable');
        marker = owner;
      },
    )..bind(client);
  });
  tearDown(() async {
    await links.dispose();
    await client.dispose();
  });

  test(
    'email requests use the configured callback and the signup resend type',
    () async {
      final auth = _EmailAuth(_SupabaseStub(client));
      await auth.requestPasswordReset(' lifter@example.invalid ');
      await auth.resendConfirmation(' lifter@example.invalid ');
      expect(requests.map((r) => r.url.path), [
        '/auth/v1/recover',
        '/auth/v1/resend',
      ]);
      for (final request in requests) {
        expect(
          request.url.queryParameters['redirect_to'],
          AuthService.callbackUrl,
        );
        expect(jsonDecode(request.body)['email'], 'lifter@example.invalid');
      }
      expect(jsonDecode(requests.last.body)['type'], 'signup');
      expect(client.auth.currentSession, isNull);
    },
  );

  test(
    'mobile PKCE recovery survives closing the requesting app before opening email',
    () async {
      await links.dispose();
      await client.dispose();
      final storage = _PkceStorage();
      SupabaseClient createClient() => SupabaseClient(
        'https://test.invalid',
        'synthetic',
        authOptions: AuthClientOptions(
          autoRefreshToken: false,
          authFlowType: AuthFlowType.pkce,
          pkceAsyncStorage: storage,
        ),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/token')) {
            expect(request.url.queryParameters['grant_type'], 'pkce');
            expect(jsonDecode(request.body)['code_verifier'], isNotEmpty);
            return http.Response(
              jsonEncode(
                Session(
                  accessToken: 'synthetic',
                  tokenType: 'bearer',
                  refreshToken: 'refresh',
                  expiresIn: 3600,
                  user: recoveryUser,
                ).toJson(),
              ),
              200,
            );
          }
          return http.Response('{}', 200);
        }),
      );
      client = createClient();
      await _EmailAuth(
        _SupabaseStub(client),
      ).requestPasswordReset('lifter@example.invalid');
      expect(storage.values.values.single, endsWith('/passwordRecovery'));
      await client.dispose();
      client = createClient();
      links = AuthLinkService(
        readRecoveryOwner: () => marker,
        writeRecoveryOwner: (owner) async => marker = owner,
      )..bind(client);
      final callback = Uri.parse(
        '${AuthService.callbackUrl}?code=synthetic-code',
      );
      links.inspectCallback(callback);
      await client.auth.getSessionFromUrl(callback);
      await Future<void>.delayed(Duration.zero);
      expect(links.state.phase, AuthLinkPhase.recovery);
      expect(links.state.userId, recoveryOwner);
      expect(storage.values, isEmpty);
    },
  );

  test(
    'abandoning a failed replacement link still signs out the unfinished recovery session',
    () async {
      await openRecovery();
      links.inspectCallback(
        Uri.parse('${AuthService.callbackUrl}?code=replacement'),
      );
      await links.leave();
      expect(client.auth.currentSession, isNull);
      expect(marker, isNull);
    },
  );

  test('only a verified recovery callback enables a password update', () async {
    expect(
      links.inspectCallback(Uri.parse('other://login-callback/?code=bad')),
      isFalse,
    );
    expect(links.inspectCallback(Uri.parse(AuthService.callbackUrl)), isFalse);
    await expectLater(links.updatePassword('new-password'), throwsStateError);
    await openRecovery();
    expect(links.state.phase, AuthLinkPhase.recovery);
    expect(links.state.userId, recoveryOwner);
    expect(marker, recoveryOwner);
    await links.updatePassword('new-password');
    expect(links.state.phase, AuthLinkPhase.complete);
    expect(marker, isNull);
    expect(jsonDecode(requests.last.body)['password'], 'new-password');
    expect(client.auth.currentUser?.id, recoveryOwner);
  });

  test(
    'refresh and profile events preserve recovery; normal login cannot enable it',
    () async {
      await openRecovery();
      links.handleAuthState(
        AuthState(AuthChangeEvent.tokenRefreshed, client.auth.currentSession),
      );
      links.handleAuthState(
        AuthState(AuthChangeEvent.userUpdated, client.auth.currentSession),
      );
      expect(links.state.phase, AuthLinkPhase.recovery);
      links.handleAuthState(
        AuthState(AuthChangeEvent.signedIn, client.auth.currentSession),
      );
      expect(links.state.phase, AuthLinkPhase.idle);
      await expectLater(links.updatePassword('new-password'), throwsStateError);
    },
  );

  test(
    'interrupted recovery restores only for its authenticated owner',
    () async {
      await openRecovery();
      await links.dispose();
      links = AuthLinkService(
        readRecoveryOwner: () => marker,
        writeRecoveryOwner: (id) async => marker = id,
      )..bind(client);
      await links.restore();
      expect(links.state.phase, AuthLinkPhase.recovery);
      await client.auth.recoverSession(
        jsonEncode(client.auth.currentSession!.toJson()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(links.state.phase, AuthLinkPhase.recovery);
      await links.leave();
      expect(client.auth.currentSession, isNull);
      expect(marker, isNull);
      marker = recoveryOwner;
      await links.restore();
      expect(links.state.phase, AuthLinkPhase.idle);
      expect(marker, isNull);
    },
  );

  test(
    'duplicate submits and new callbacks cannot replace a pending password update',
    () async {
      await openRecovery();
      updateGate = Completer<void>();
      final first = links.updatePassword('new-password');
      await Future<void>.delayed(Duration.zero);
      await links.updatePassword('duplicate-password');
      expect(
        links.inspectCallback(
          Uri.parse('${AuthService.callbackUrl}?code=another'),
        ),
        isFalse,
      );
      expect(requests.where((r) => r.method == 'PUT'), hasLength(1));
      updateGate!.complete();
      await first;
      expect(links.state.phase, AuthLinkPhase.complete);
    },
  );

  test(
    'failed password update is retryable and failed cleanup does not repeat it',
    () async {
      await openRecovery();
      failPassword = true;
      await links.updatePassword('new-password');
      expect(links.state.phase, AuthLinkPhase.recovery);
      expect(links.state.error, contains('stronger'));
      expect(marker, recoveryOwner);
      failPassword = false;
      failClear = true;
      await links.updatePassword('new-password');
      expect(links.state.passwordSaved, isTrue);
      expect(links.state.error, contains('Finish'));
      failClear = false;
      await links.updatePassword('new-password');
      expect(links.state.phase, AuthLinkPhase.complete);
      expect(requests.where((r) => r.method == 'PUT'), hasLength(2));
    },
  );

  test(
    'expired callback produces a safe error and cannot alter an account',
    () async {
      final callback = Uri.parse(
        '${AuthService.callbackUrl}#error=access_denied&error_code=otp_expired&error_description=Expired',
      );
      links.inspectCallback(callback);
      try {
        await client.auth.getSessionFromUrl(callback);
        fail('Expired callback must fail');
      } on AuthException catch (error, stack) {
        // Mirrors Supabase Flutter forwarding callback failures to its auth stream.
        // ignore: invalid_use_of_internal_member
        client.auth.notifyException(error, stack);
      }
      await Future<void>.delayed(Duration.zero);
      expect(links.state.phase, AuthLinkPhase.invalid);
      await expectLater(links.updatePassword('new-password'), throwsStateError);
      expect(requests, isEmpty);
    },
  );
}

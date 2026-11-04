import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/config/supabase_config.dart';
import 'package:leon/services/auth_service.dart';
import 'package:leon/services/supabase_service.dart';

void main() {
  group('Supabase Configuration & Services', () {
    test('SupabaseConfig contains valid project URL and keys', () {
      expect(SupabaseConfig.url, startsWith('https://'));
      expect(SupabaseConfig.url, contains('.supabase.co'));
      expect(SupabaseConfig.publishableKey, isNotEmpty);
      expect(SupabaseConfig.anonKey, isNotEmpty);
    });

    test('Riverpod container resolves SupabaseService and AuthService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final supabaseService = container.read(supabaseServiceProvider);
      final authService = container.read(authServiceProvider);

      expect(supabaseService, isA<SupabaseService>());
      expect(authService, isA<AuthService>());
      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentUserId, isNull);
    });
  });
}

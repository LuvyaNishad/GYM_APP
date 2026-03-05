/// LEON Supabase Service (placeholder)
///
/// This file will hold all direct Supabase client interactions:
/// - Initialization
/// - Authentication helpers
/// - Realtime subscriptions
///
/// Backend implementation is deferred. Wire up the Supabase client here
/// when the backend phase begins.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that exposes the SupabaseService singleton.
/// Replace the placeholder with a real implementation when Supabase is wired.
final supabaseServiceProvider = Provider<SupabaseService>(
  (ref) => SupabaseService(),
);

/// Placeholder Supabase service.
class SupabaseService {
  SupabaseService();

  // TODO(backend): Initialize supabase_flutter client.
  // await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);

  // TODO(backend): Expose the client via a getter:
  // SupabaseClient get client => Supabase.instance.client;
}

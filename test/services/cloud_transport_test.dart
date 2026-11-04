import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:leon/services/cloud_sync_engine.dart';
import 'package:leon/services/supabase_service.dart';
import 'package:leon/services/sync_service.dart';
import 'cloud_sync_engine_test.dart' show owner, WorkspaceMemory, workout, clone;

class HttpCloud extends SupabaseService {
  HttpCloud(this.fakeClient);
  final SupabaseClient fakeClient;
  @override
  SupabaseClient get client => fakeClient;
  @override
  String? get currentUserId => owner;
}
void main() {
  test('real Supabase query requests ascending owner-scoped cursor pages', () async {
    final requests = <Uri>[];
    final client = SupabaseClient('https://test.invalid', 'synthetic-publishable-key',
      httpClient: MockClient((request) async {
        requests.add(request.url);
        expect(request.method, 'GET');
        expect(request.url.queryParameters['user_id'], 'eq.$owner');
        final cursor = int.parse(request.url.queryParameters['sequence']!.substring(3));
        final rows = [for (var sequence = 1; sequence <= 3; sequence++)
          if (sequence > cursor) {'collection': 'workouts', 'record_key': 'workout-$sequence',
            'data': clone(workout(40 + sequence.toDouble(), id: 'workout-$sequence').toJson()),
            'revision': 1, 'sequence': sequence}];
        final ascending = request.url.queryParameters['order']!.startsWith('sequence.asc');
        return http.Response(jsonEncode(ascending ? rows : rows.reversed.toList()), 200,
          request: request, headers: {'content-type': 'application/json'});
      }));
    try {
      final hive = WorkspaceMemory();
      await CloudSyncEngine(hive, SupabaseCloudTransport(HttpCloud(client))).synchronize();
      expect(hive.readAll('workouts', (j) => j), hasLength(3));
      expect(requests.first.queryParameters['order'], startsWith('sequence.asc'));
      expect(requests.last.queryParameters['sequence'], 'gt.3');
    } finally { await client.dispose(); }
  });
}

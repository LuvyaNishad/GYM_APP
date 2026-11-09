import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:leon/services/cloud_sync_engine.dart';
import 'package:leon/services/supabase_service.dart';
import 'package:leon/services/sync_service.dart';
import 'package:leon/services/avatar_service.dart';
import 'package:leon/features/profile/models/avatar_reference.dart';
import 'avatar_service_test.dart' show photoBytes, photoId;
import 'cloud_sync_engine_test.dart'
    show owner, WorkspaceMemory, workout, clone;

class HttpCloud extends SupabaseService {
  HttpCloud(this.fakeClient);
  final SupabaseClient fakeClient;
  @override
  SupabaseClient get client => fakeClient;
  @override
  String? get currentUserId => owner;
}

void main() {
  test(
    'private photo upload completes before publishing its profile reference',
    () async {
      final events = <String>[];
      var offline = true;
      final client = SupabaseClient(
        'https://test.invalid',
        'synthetic-publishable-key',
        httpClient: MockClient((request) async {
          if (request.url.path.contains('/storage/')) {
            events.add('photo');
            expect(request.url.path, endsWith('/avatars/$owner/$photoId.jpg'));
            expect(
              request.headers['content-type'],
              startsWith('multipart/form-data;'),
            );
            expect(
              utf8
                  .decode(request.bodyBytes, allowMalformed: true)
                  .toLowerCase(),
              contains('content-type: image/jpeg'),
            );
            if (offline) {
              return http.Response(
                '{"message":"Offline","statusCode":"503"}',
                503,
                request: request,
              );
            }
            return http.Response(
              jsonEncode({'Key': 'avatars/$owner/$photoId.jpg'}),
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }
          events.add('profile');
          expect(request.url.path, endsWith('/rpc/apply_cloud_changes'));
          expect(jsonDecode(request.body)['expected_user_id'], owner);
          return http.Response(
            '[]',
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      try {
        final hive = WorkspaceMemory();
        final supabase = HttpCloud(client);
        final avatars = AvatarService(
          hive,
          transport: SupabaseAvatarTransport(supabase),
        );
        await avatars.save(AvatarReference.photo(photoId), bytes: photoBytes());
        final transport = SupabaseCloudTransport(supabase, avatars: avatars);
        final batch = [
          {
            'collection': 'user',
            'data': {'avatar_url': AvatarReference.photo(photoId)},
          },
        ];
        await expectLater(transport.push(owner, batch), throwsA(anything));
        expect(events, ['photo']);
        offline = false;
        await transport.push(owner, batch);
        expect(events, ['photo', 'photo', 'profile']);
      } finally {
        await client.dispose();
      }
    },
  );
  test(
    'real Supabase query requests ascending owner-scoped cursor pages',
    () async {
      final requests = <Uri>[];
      final client = SupabaseClient(
        'https://test.invalid',
        'synthetic-publishable-key',
        httpClient: MockClient((request) async {
          requests.add(request.url);
          expect(request.method, 'GET');
          expect(request.url.queryParameters['user_id'], 'eq.$owner');
          final cursor = int.parse(
            request.url.queryParameters['sequence']!.substring(3),
          );
          final rows = [
            for (var sequence = 1; sequence <= 3; sequence++)
              if (sequence > cursor)
                {
                  'collection': 'workouts',
                  'record_key': 'workout-$sequence',
                  'data': clone(
                    workout(
                      40 + sequence.toDouble(),
                      id: 'workout-$sequence',
                    ).toJson(),
                  ),
                  'revision': 1,
                  'sequence': sequence,
                },
          ];
          final ascending = request.url.queryParameters['order']!.startsWith(
            'sequence.asc',
          );
          return http.Response(
            jsonEncode(ascending ? rows : rows.reversed.toList()),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      try {
        final hive = WorkspaceMemory();
        await CloudSyncEngine(
          hive,
          SupabaseCloudTransport(HttpCloud(client)),
        ).synchronize();
        expect(hive.readAll('workouts', (j) => j), hasLength(3));
        expect(
          requests.first.queryParameters['order'],
          startsWith('sequence.asc'),
        );
        expect(requests.last.queryParameters['sequence'], 'gt.3');
      } finally {
        await client.dispose();
      }
    },
  );
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/cloud_sync_engine.dart';
import '../../../services/hive_service.dart';
import '../../../services/sync_service.dart';

class SyncConflictsScreen extends ConsumerWidget {
  const SyncConflictsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflicts = ref.watch(syncServiceProvider).conflicts;
    return Scaffold(
      appBar: AppBar(title: const Text('Review sync conflicts')),
      body: conflicts.isEmpty
          ? const Center(child: Text('No conflicts to review.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'These records changed on more than one device. Review both versions before choosing one.',
                ),
                const SizedBox(height: 16),
                for (final entry in conflicts.entries)
                  ListTile(
                    title: Text(_title(entry.value)),
                    subtitle: Text(_label(entry.value['collection'] as String)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _ConflictDetail(
                          recordKey: entry.key,
                          remote: entry.value,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

String _label(String value) => value
    .replaceAll('_', ' ')
    .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
String _title(JsonMap remote) {
  final data = remote['data'];
  if (data is Map) {
    return '${data['name'] ?? data['display_name'] ?? _label(remote['record_key'] as String)}';
  }
  return '${_label(remote['collection'] as String)} · deleted in cloud';
}

String _details(Object? data, [String prefix = '']) {
  if (data == null) return prefix.isEmpty ? 'Deleted' : '$prefix: Not set';
  if (data is String && (data.startsWith('{') || data.startsWith('['))) {
    try {
      return _details(jsonDecode(data), prefix);
    } catch (_) {}
  }
  if (data is Map) {
    return data.entries
        .map(
          (e) => _details(
            e.value,
            [
              prefix,
              _label(e.key.toString()),
            ].where((v) => v.isNotEmpty).join(' · '),
          ),
        )
        .join('\n');
  }
  if (data is List) {
    return data.isEmpty
        ? '$prefix: None'
        : data.indexed
              .map((e) => _details(e.$2, '$prefix ${e.$1 + 1}'))
              .join('\n');
  }
  return '$prefix: $data';
}

class _ConflictDetail extends ConsumerStatefulWidget {
  const _ConflictDetail({required this.recordKey, required this.remote});
  final String recordKey;
  final JsonMap remote;
  @override
  ConsumerState<_ConflictDetail> createState() => _ConflictDetailState();
}

class _ConflictDetailState extends ConsumerState<_ConflictDetail> {
  bool _busy = false;
  String? _error;
  Future<void> _choose(bool local) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(syncServiceProvider.notifier)
          .resolveConflict(
            widget.recordKey,
            useLocal: local,
            reviewedRevision: widget.remote['revision'] as int,
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error =
              'Could not apply this choice. Go back, refresh and review again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = CloudSyncEngine.records(
      ref.read(hiveServiceProvider).snapshot(),
    )[widget.recordKey];
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(_title(widget.remote))),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'This device',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            SelectableText(_details(local)),
            const SizedBox(height: 24),
            const Text(
              'Cloud',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            SelectableText(_details(widget.remote['data'])),
            const SizedBox(height: 24),
            if (_error != null) Text(_error!),
            FilledButton(
              onPressed: _busy ? null : () => _choose(true),
              child: const Text('Keep this device’s version'),
            ),
            OutlinedButton(
              onPressed: _busy ? null : () => _choose(false),
              child: const Text('Use cloud version'),
            ),
          ],
        ),
      ),
    );
  }
}

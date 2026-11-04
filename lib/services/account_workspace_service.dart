import 'backup_service.dart';
import 'cloud_sync_engine.dart';
import 'hive_service.dart';
import 'supabase_service.dart';
import 'sync_service.dart';

/// Session identity selects storage; record contents never select an owner.
class AccountWorkspaceService {
  AccountWorkspaceService(this.supabase, {this.transport});
  final SupabaseService supabase;
  final CloudTransport? transport;
  static const readyKey = 'cloud_account_ready_v1';
  static const importSourceKey = 'pending_guest_import_source_v1';

  Future<HiveService> selectSession() async {
    final user = supabase.currentUser;
    final current = HiveService.activeWorkspaceId;
    final workspace = user == null
        ? (current.startsWith('guest') ? current : HiveService.guestWorkspaceId)
        : HiveService.accountWorkspaceId(user.id);
    final hive = await HiveService.openWorkspace(workspace);
    final source = HiveService.pendingGuestSource;
    if (user != null && source != null) {
      if (source != workspace) {
        await hive.putSettingChecked(importSourceKey, source);
      }
      await HiveService.clearGuestSource();
    }
    if (supabase.currentUserId != user?.id) {
      throw StateError('Account changed.');
    }
    await HiveService.selectWorkspace(workspace);
    if (supabase.currentUserId != user?.id) {
      throw StateError('Account changed.');
    }
    return hive;
  }

  bool needsEntry(HiveService hive) =>
      hive.ownerUserId != null &&
      (hive.getSetting<bool>(readyKey) != true ||
          hive.getSetting<String>(importSourceKey) != null);

  Future<BackupPreview?> prepare(HiveService hive) async {
    final engine = CloudSyncEngine(
      hive,
      transport ?? SupabaseCloudTransport(supabase),
    );
    await engine.synchronize();
    if (supabase.currentUserId != hive.ownerUserId) {
      throw StateError('Account changed.');
    }
    final source = hive.getSetting<String>(importSourceKey);
    if (source == null) {
      await hive.putSettingChecked(readyKey, true);
      return null;
    }
    final guest = await HiveService.openWorkspace(source);
    final bytes = await BackupService(guest).export();
    final preview = await BackupService(hive).preview(bytes);
    // A newly provisioned anonymous identity is this guest's own workspace.
    if (supabase.currentUser?.isAnonymous == true) {
      await finish(hive, preview, RestoreMode.keepExisting);
      return null;
    }
    return preview;
  }

  Future<void> finish(
    HiveService hive,
    BackupPreview preview,
    RestoreMode? mode,
  ) async {
    if (supabase.currentUserId != hive.ownerUserId) {
      throw StateError('Account changed.');
    }
    if (mode != null) await BackupService(hive).restore(preview, mode);
    await hive.putSettingChecked(readyKey, true);
    await hive.deleteSettingChecked(importSourceKey);
  }
}

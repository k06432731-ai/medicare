import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/notification_repository.dart';
import '../data/models/notification_model.dart';

// ── Liste des notifications ───────────────────────────────────────────────────

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  return ref.watch(notificationRepositoryProvider).getMyNotifications();
});

// ── Compteur non-lus ──────────────────────────────────────────────────────────

final unreadCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(notificationRepositoryProvider).getUnreadCount();
});

// ── Notifier (actions) ────────────────────────────────────────────────────────

class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  final NotificationRepository _repo;
  final Ref _ref;
  NotificationNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<void> markRead(int id) async {
    try {
      await _repo.markRead(id);
      _ref.invalidate(notificationsProvider);
      _ref.invalidate(unreadCountProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAllRead() async {
    state = const AsyncValue.loading();
    try {
      await _repo.markAllRead();
      _ref.invalidate(notificationsProvider);
      _ref.invalidate(unreadCountProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<void>>((ref) {
  return NotificationNotifier(ref.watch(notificationRepositoryProvider), ref);
});

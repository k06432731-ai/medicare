import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/notification_repository.dart';
import '../data/models/notification_model.dart';

// ── État paginé ───────────────────────────────────────────────────────────────

class NotificationListState {
  final List<NotificationModel> items;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? error;

  const NotificationListState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  NotificationListState copyWith({
    List<NotificationModel>? items,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? error,
  }) =>
      NotificationListState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        error: error,
      );
}

// ── Notifier paginé ───────────────────────────────────────────────────────────

class NotificationListNotifier
    extends StateNotifier<NotificationListState> {
  static const _pageSize = 20;
  final NotificationRepository _repo;

  NotificationListNotifier(this._repo) : super(const NotificationListState()) {
    loadFirst();
  }

  Future<void> loadFirst() async {
    state = state.copyWith(isLoading: true, page: 1, items: [], hasMore: true);
    try {
      final items = await _repo.getMyNotifications(page: 1, pageSize: _pageSize);
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length >= _pageSize,
        page: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.page + 1;
      final items =
          await _repo.getMyNotifications(page: nextPage, pageSize: _pageSize);
      state = state.copyWith(
        items: [...state.items, ...items],
        isLoading: false,
        hasMore: items.length >= _pageSize,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final notificationListProvider =
    StateNotifierProvider<NotificationListNotifier, NotificationListState>(
        (ref) {
  return NotificationListNotifier(ref.watch(notificationRepositoryProvider));
});

// ── FutureProvider simple (conservé pour compatibilité badge) ─────────────────

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

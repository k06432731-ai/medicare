import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/messaging_repository.dart';
import '../data/models/conversation_model.dart';
import '../data/models/message_model.dart';

// ── Conversations ─────────────────────────────────────────────────────────────

final conversationsProvider = FutureProvider<List<ConversationModel>>((ref) async {
  return ref.watch(messagingRepositoryProvider).getConversations();
});

// ── Messages par conversation ─────────────────────────────────────────────────

final messagesProvider =
    FutureProvider.family<List<MessageModel>, int>((ref, conversationId) async {
  return ref.watch(messagingRepositoryProvider).getMessages(conversationId);
});

// ── Notifier pour envoi + markRead ───────────────────────────────────────────

class MessagingNotifier extends StateNotifier<AsyncValue<void>> {
  final MessagingRepository _repo;
  final Ref _ref;
  MessagingNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<void> sendMessage(int conversationId, String content) async {
    state = const AsyncValue.loading();
    try {
      await _repo.sendMessage(conversationId, content);
      _ref.invalidate(messagesProvider(conversationId));
      _ref.invalidate(conversationsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markRead(int conversationId) async {
    try {
      await _repo.markRead(conversationId);
      _ref.invalidate(conversationsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<ConversationModel?> findOrCreate({
    int? doctorId,
    int? patientId,
  }) async {
    try {
      return await _repo.findOrCreate(
          doctorId: doctorId, patientId: patientId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final messagingNotifierProvider =
    StateNotifierProvider<MessagingNotifier, AsyncValue<void>>((ref) {
  return MessagingNotifier(ref.watch(messagingRepositoryProvider), ref);
});

// ── Total des messages non-lus (pour badge onglet) ───────────────────────────

final totalUnreadMessagesProvider = Provider<int>((ref) {
  return ref.watch(conversationsProvider).whenOrNull(
            data: (list) {
              // userId sera calculé dans le widget via auth
              // on retourne la somme brute pour filtrer côté widget
              return list.fold<int>(
                  0, (sum, c) => sum + c.patientUnread + c.doctorUnread);
            },
          ) ??
      0;
});

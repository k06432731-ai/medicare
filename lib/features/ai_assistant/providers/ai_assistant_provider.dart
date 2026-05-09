import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/ai_repository.dart';
import '../data/models/chat_message_model.dart';
import '../data/models/triage_result_model.dart';

// ── Mode de l'assistant ───────────────────────────────────────────────────────

enum AiMode { chat, triage }

final aiModeProvider = StateProvider<AiMode>((ref) => AiMode.chat);

// ── État du chat ──────────────────────────────────────────────────────────────

class AiChatState {
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final String? error;

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AiChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    String? error,
  }) =>
      AiChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ── Notifier chat ─────────────────────────────────────────────────────────────

class AiChatNotifier extends StateNotifier<AiChatState> {
  final AiRepository _repo;

  AiChatNotifier(this._repo) : super(const AiChatState()) {
    _welcome();
  }

  void _welcome() {
    state = state.copyWith(messages: [
      ChatMessageModel.assistant(
        'Bonjour ! Je suis **MediCare AI**, votre assistant santé 🩺\n\n'
        'Posez-moi vos questions sur la santé et je vous répondrai avec des conseils généraux.\n\n'
        '⚠️ Je ne remplace pas une consultation médicale. En cas d\'urgence, appelez le **190**.',
      ),
    ]);
  }

  Future<void> send(String content) async {
    if (content.trim().isEmpty || state.isLoading) return;

    final userMsg = ChatMessageModel.user(content.trim());
    final typingMsg = ChatMessageModel.assistant('', isTyping: true);

    // Ajoute le message user + indicateur de frappe
    state = state.copyWith(
      messages: [...state.messages, userMsg, typingMsg],
      isLoading: true,
      error: null,
    );

    try {
      // N'envoie pas l'indicateur de frappe dans l'historique
      final history = state.messages
          .where((m) => !m.isTyping)
          .toList()
        ..add(userMsg);

      final reply = await _repo.chat(history);

      // Remplace l'indicateur par la vraie réponse
      final updated = state.messages.where((m) => !m.isTyping).toList()
        ..add(ChatMessageModel.assistant(reply));

      state = state.copyWith(messages: updated, isLoading: false);
    } catch (e) {
      final updated =
          state.messages.where((m) => !m.isTyping).toList();
      state = state.copyWith(
        messages: updated,
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void reset() {
    state = const AiChatState();
    _welcome();
  }
}

final aiChatProvider =
    StateNotifierProvider.autoDispose<AiChatNotifier, AiChatState>((ref) {
  return AiChatNotifier(ref.watch(aiRepositoryProvider));
});

// ── État du triage ────────────────────────────────────────────────────────────

class TriageState {
  final TriageResultModel? result;
  final bool isLoading;
  final String? error;

  const TriageState({this.result, this.isLoading = false, this.error});

  TriageState copyWith({
    TriageResultModel? result,
    bool? isLoading,
    String? error,
    bool clearResult = false,
  }) =>
      TriageState(
        result: clearResult ? null : (result ?? this.result),
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class TriageNotifier extends StateNotifier<TriageState> {
  final AiRepository _repo;
  TriageNotifier(this._repo) : super(const TriageState());

  Future<void> analyze(String symptoms) async {
    if (symptoms.trim().isEmpty || state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, clearResult: true);
    try {
      final result = await _repo.triage(symptoms.trim());
      state = state.copyWith(result: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void reset() => state = const TriageState();
}

final triageProvider =
    StateNotifierProvider.autoDispose<TriageNotifier, TriageState>((ref) {
  return TriageNotifier(ref.watch(aiRepositoryProvider));
});

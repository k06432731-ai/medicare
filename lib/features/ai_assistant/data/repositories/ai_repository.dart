import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/ai_config.dart';
import '../models/chat_message_model.dart';
import '../models/triage_result_model.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) => AiRepository());

class AiRepository {
  late final Dio _dio = Dio(BaseOptions(
    baseUrl: AiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Authorization': 'Bearer ${AiConfig.openAiKey}',
      'Content-Type': 'application/json',
    },
  ));

  // ── Chat ──────────────────────────────────────────────────────────────────

  /// Envoie l'historique de conversation et retourne la réponse du modèle.
  Future<String> chat(List<ChatMessageModel> history) async {
    if (!AiConfig.isConfigured) {
      throw Exception(
          '⚠️ Clé OpenAI non configurée. Ajoutez votre clé dans ai_config.dart');
    }

    final messages = [
      {'role': 'system', 'content': AiConfig.systemChatPrompt},
      ...history.where((m) => !m.isTyping).map((m) => m.toApiMessage()),
    ];

    try {
      final res = await _dio.post('/chat/completions', data: {
        'model': AiConfig.model,
        'messages': messages,
        'temperature': AiConfig.temperature,
        'max_tokens': AiConfig.maxTokens,
      });
      return res.data['choices'][0]['message']['content'] as String;
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message'] as String?;
      throw Exception(msg ?? 'Erreur OpenAI (${e.response?.statusCode})');
    }
  }

  // ── Triage ────────────────────────────────────────────────────────────────

  /// Analyse les symptômes et retourne un TriageResultModel.
  Future<TriageResultModel> triage(String symptoms) async {
    if (!AiConfig.isConfigured) {
      throw Exception(
          '⚠️ Clé OpenAI non configurée. Ajoutez votre clé dans ai_config.dart');
    }

    try {
      final res = await _dio.post('/chat/completions', data: {
        'model': AiConfig.model,
        'messages': [
          {'role': 'system', 'content': AiConfig.systemTriagePrompt},
          {'role': 'user', 'content': symptoms},
        ],
        'temperature': 0.3, // plus déterministe pour le triage
        'max_tokens': 300,
      });

      final raw = res.data['choices'][0]['message']['content'] as String;
      final result = TriageResultModel.tryParse(raw);
      if (result == null) throw Exception('Réponse du modèle non analysable');
      return result;
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message'] as String?;
      throw Exception(msg ?? 'Erreur OpenAI (${e.response?.statusCode})');
    }
  }
}

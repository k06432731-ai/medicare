import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/chat_message_model.dart';
import '../models/triage_result_model.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return AiRepository(dio);
});

class AiRepository {
  final Dio _dio;
  const AiRepository(this._dio);

  // ── Chat ──────────────────────────────────────────────────────────────────

  /// Envoie l'historique de conversation au backend et retourne la réponse.
  /// Le backend appelle OpenAI côté serveur — aucune clé dans l'APK.
  Future<String> chat(List<ChatMessageModel> history) async {
    final messages = history
        .where((m) => !m.isTyping)
        .map((m) => m.toApiMessage())
        .toList();

    try {
      final res = await _dio.post(
        ApiConstants.aiAssistantChat,
        data: {
          'messages': messages,
          'mode': 'chat',
        },
      );
      return res.data['data']['reply'] as String;
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message'] as String?;
      throw Exception(msg ?? 'Erreur IA (${e.response?.statusCode})');
    }
  }

  // ── Triage ────────────────────────────────────────────────────────────────

  /// Analyse les symptômes via le backend et retourne un TriageResultModel.
  Future<TriageResultModel> triage(String symptoms) async {
    try {
      final res = await _dio.post(
        ApiConstants.aiDoctorTriage,
        data: {
          'symptoms': symptoms,
          'mode': 'triage',
        },
      );

      final data = res.data['data'] as Map<String, dynamic>;
      final result = TriageResultModel.fromJson(data);
      return result;
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message'] as String?;
      throw Exception(msg ?? 'Erreur triage (${e.response?.statusCode})');
    }
  }
}

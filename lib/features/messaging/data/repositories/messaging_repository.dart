import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepository(ref.watch(dioClientProvider));
});

class MessagingRepository {
  final Dio _dio;
  MessagingRepository(this._dio);

  // ── Conversations ──────────────────────────────────────────────────────────

  Future<List<ConversationModel>> getConversations() async {
    try {
      final res = await _dio.get('/messaging-engine/conversations');
      final data = res.data['data'] as List? ?? [];
      return data
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<ConversationModel> findOrCreate({int? doctorId, int? patientId}) async {
    try {
      final body = <String, dynamic>{};
      if (doctorId != null) body['doctorId'] = doctorId;
      if (patientId != null) body['patientId'] = patientId;
      final res = await _dio.post('/messaging-engine/find-or-create', data: body);
      return ConversationModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── Messages ───────────────────────────────────────────────────────────────

  Future<List<MessageModel>> getMessages(int conversationId) async {
    try {
      final res = await _dio.get('/messaging-engine/messages/$conversationId');
      final data = res.data['data'] as List? ?? [];
      return data
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<MessageModel> sendMessage(int conversationId, String content) async {
    try {
      final res = await _dio.post('/messaging-engine/send',
          data: {'conversationId': conversationId, 'content': content});
      return MessageModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<void> markRead(int conversationId) async {
    try {
      await _dio.put('/messaging-engine/mark-read/$conversationId');
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}

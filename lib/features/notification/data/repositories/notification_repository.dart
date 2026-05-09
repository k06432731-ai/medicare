import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../models/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(dioClientProvider));
});

class NotificationRepository {
  final Dio _dio;
  NotificationRepository(this._dio);

  Future<List<NotificationModel>> getMyNotifications() async {
    try {
      final res = await _dio.get('/notification-engine/my');
      final data = res.data['data'] as List? ?? [];
      return data
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final res = await _dio.get('/notification-engine/unread-count');
      return res.data['count'] as int? ?? 0;
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _dio.put('/notification-engine/mark-read/$id');
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.put('/notification-engine/mark-all-read');
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}

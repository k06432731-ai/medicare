import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../models/availability_model.dart';
import '../models/schedule_block_model.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(ref.watch(dioClientProvider));
});

class ScheduleRepository {
  final Dio _dio;
  ScheduleRepository(this._dio);

  // ── Availability ────────────────────────────────────────────────────────────

  Future<List<AvailabilityModel>> getAvailability() async {
    try {
      final res = await _dio.get('/schedule-engine/availability');
      final data = res.data['data'] as List? ?? [];
      return data
          .map((e) => AvailabilityModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<List<AvailabilityModel>> setAvailability(
      List<AvailabilityModel> slots) async {
    try {
      final res = await _dio.post('/schedule-engine/availability', data: {
        'slots': slots.map((s) => s.toJson()).toList(),
      });
      final data = res.data['data'] as List? ?? [];
      return data
          .map((e) => AvailabilityModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── Blocks ──────────────────────────────────────────────────────────────────

  Future<List<ScheduleBlockModel>> getBlocks() async {
    try {
      final res = await _dio.get('/schedule-engine/blocks');
      final data = res.data['data'] as List? ?? [];
      return data
          .map((e) => ScheduleBlockModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<ScheduleBlockModel> addBlock({
    required String blockDate,
    String startTime = '00:00',
    String endTime = '23:59',
    String reason = 'Indisponible',
  }) async {
    try {
      final res = await _dio.post('/schedule-engine/blocks', data: {
        'blockDate': blockDate,
        'startTime': startTime,
        'endTime': endTime,
        'reason': reason,
      });
      return ScheduleBlockModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<void> removeBlock(int id) async {
    try {
      await _dio.delete('/schedule-engine/blocks/$id');
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── Public availability (patient-facing) ────────────────────────────────────

  /// Retourne les créneaux disponibles d'un médecin pour une date donnée.
  /// Utilisé dans BookAppointmentScreen pour griser les créneaux bloqués.
  Future<Map<String, dynamic>> getPublicAvailability({
    required int doctorId,
    required String date, // format YYYY-MM-DD
  }) async {
    try {
      final res = await _dio.get(
        '/schedule-engine/public-availability',
        queryParameters: {'doctorId': doctorId, 'date': date},
      );
      return res.data as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      // Graceful degradation: if endpoint absent, return empty (all slots shown)
      if (e.response?.statusCode == 404) return {};
      throw parseDioError(e);
    }
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../models/recovery_case_model.dart';
import '../models/recovery_stats_model.dart';
import '../models/risk_score_model.dart';
import '../models/staff_task_model.dart';

final recoveryRepositoryProvider = Provider<RecoveryRepository>((ref) {
  return RecoveryRepository(ref.watch(dioClientProvider));
});

class RecoveryRepository {
  final Dio _dio;
  RecoveryRepository(this._dio);

  // ── Stats ─────────────────────────────────────────────────────────────────

  Future<RecoveryStats> getStats() async {
    try {
      final res = await _dio.get('/recovery-engine/stats');
      return RecoveryStats.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── Cases ─────────────────────────────────────────────────────────────────

  Future<List<RecoveryCaseModel>> getCases({
    String? status,
    String? type,
    String? priority,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
      if (status != null) params['status'] = status;
      if (type != null) params['type'] = type;
      if (priority != null) params['priority'] = priority;
      final res = await _dio.get('/recovery-engine/cases', queryParameters: params);
      final data = res.data['data'] as List? ?? [];
      return data.map((e) => RecoveryCaseModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<RecoveryCaseModel> updateCase(int id, String status, {String? notes}) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (notes != null) body['notes'] = notes;
      final res = await _dio.put('/recovery-engine/cases/$id', data: body);
      return RecoveryCaseModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── Staff Tasks ────────────────────────────────────────────────────────────

  Future<List<StaffTaskModel>> getStaffTasks({
    String status = 'pending',
    int page = 1,
    int pageSize = 30,
  }) async {
    try {
      final params = <String, dynamic>{'status': status, 'page': page, 'pageSize': pageSize};
      final res = await _dio.get('/recovery-engine/staff-tasks', queryParameters: params);
      final data = res.data['data'] as List? ?? [];
      return data.map((e) => StaffTaskModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<void> markTaskDone(int id) async {
    try {
      await _dio.put('/recovery-engine/staff-tasks/$id', data: {'status': 'done'});
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── Risk Scores ────────────────────────────────────────────────────────────

  Future<List<RiskScoreModel>> getRiskScores({String? level}) async {
    try {
      final params = <String, dynamic>{};
      if (level != null) params['level'] = level;
      final res = await _dio.get('/recovery-engine/risk-scores', queryParameters: params);
      final data = res.data['data'] as List? ?? [];
      return data.map((e) => RiskScoreModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<Map<String, dynamic>> getDoctorView() async {
    try {
      final res = await _dio.get('/recovery-engine/doctor-view');
      return res.data['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<Map<String, dynamic>> getPatientRisk(int patientId) async {
    try {
      final res = await _dio.get('/recovery-engine/patient-risk/$patientId');
      return res.data['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}

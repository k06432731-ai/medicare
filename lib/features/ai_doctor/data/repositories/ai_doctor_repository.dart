import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/prescription_draft_model.dart';

final aiDoctorRepositoryProvider = Provider<AiDoctorRepository>((ref) {
  return AiDoctorRepository(ref.watch(dioClientProvider));
});

class AiDoctorRepository {
  final Dio _dio;
  AiDoctorRepository(this._dio);

  // ── Brouillon d'ordonnance ────────────────────────────────────────────────

  Future<PrescriptionDraftModel> prescriptionDraft({
    required String symptoms,
    String? diagnosis,
    String? patientAge,
    String? allergies,
    String? patientName,
  }) async {
    try {
      final body = <String, dynamic>{'symptoms': symptoms};
      if (diagnosis != null && diagnosis.isNotEmpty) body['diagnosis'] = diagnosis;
      if (patientAge != null && patientAge.isNotEmpty) body['patientAge'] = patientAge;
      if (allergies != null && allergies.isNotEmpty) body['allergies'] = allergies;
      if (patientName != null && patientName.isNotEmpty) body['patientName'] = patientName;

      final res = await _dio.post(ApiConstants.aiDoctorPrescriptionDraft, data: body);
      return PrescriptionDraftModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── Résumé patient ────────────────────────────────────────────────────────

  Future<String> summarizePatient(int patientId) async {
    try {
      final res = await _dio.post(ApiConstants.aiDoctorPatientSummary,
          data: {'patientId': patientId});
      return res.data['data']['summary'] as String? ?? '';
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── Suggestions diagnostiques ─────────────────────────────────────────────

  Future<DiagnosticSuggestionsModel> diagnosticSuggestions({
    required String symptoms,
    String? patientAge,
    String? medicalHistory,
  }) async {
    try {
      final body = <String, dynamic>{'symptoms': symptoms};
      if (patientAge != null && patientAge.isNotEmpty) body['patientAge'] = patientAge;
      if (medicalHistory != null && medicalHistory.isNotEmpty) body['medicalHistory'] = medicalHistory;

      final res = await _dio.post(ApiConstants.aiDoctorDiagnosticSuggestions, data: body);
      return DiagnosticSuggestionsModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}

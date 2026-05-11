import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicare/core/network/dio_client.dart';
import 'package:medicare/features/prescription/data/models/prescription_model.dart';

final prescriptionRepositoryProvider = Provider<PrescriptionRepository>((ref) {
  return PrescriptionRepository(ref.read(dioClientProvider));
});

class PrescriptionRepository {
  final Dio _dio;

  PrescriptionRepository(this._dio);

  Future<List<PrescriptionModel>> getMyPrescriptions({String? status}) async {
    try {
      final Map<String, dynamic> params = {
        'sort': 'issuedDate:desc',
        'pagination[pageSize]': '50',
        'populate': 'doctor',
      };
      if (status != null && status != 'all') {
        params['filters[status][\$eq]'] = status;
      }

      final response = await _dio.get('/prescriptions', queryParameters: params);
      final raw = response.data;
      List<dynamic> items = [];
      if (raw is Map && raw['data'] is List) {
        items = raw['data'] as List;
      } else if (raw is List) {
        items = raw;
      }
      return items.map((e) => PrescriptionModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw parseDioError(e);
    }
  }

  Future<List<PrescriptionModel>> getByPatient(int patientId) async {
    try {
      final response = await _dio.get('/prescriptions', queryParameters: {
        'filters[patient][id][\$eq]': patientId,
        'sort': 'issuedDate:desc',
        'pagination[pageSize]': '50',
        'populate': 'doctor',
      });
      final raw = response.data;
      List<dynamic> items = [];
      if (raw is Map && raw['data'] is List) {
        items = raw['data'] as List;
      } else if (raw is List) {
        items = raw;
      }
      return items.map((e) => PrescriptionModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw parseDioError(e);
    }
  }

  Future<PrescriptionModel> createPrescription(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/prescriptions', data: {'data': data});
      final raw = response.data;
      final item = raw is Map && raw['data'] != null ? raw['data'] : raw;
      return PrescriptionModel.fromJson(item as Map<String, dynamic>);
    } catch (e) {
      throw parseDioError(e);
    }
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicare/core/network/dio_client.dart';
import 'package:medicare/features/medical_record/data/models/medical_record_model.dart';

final medicalRecordRepositoryProvider = Provider<MedicalRecordRepository>((ref) {
  return MedicalRecordRepository(ref.read(dioClientProvider));
});

class MedicalRecordRepository {
  final Dio _dio;

  MedicalRecordRepository(this._dio);

  Future<List<MedicalRecordModel>> getMyRecords({String? type}) async {
    try {
      final Map<String, dynamic> params = {
        'sort': 'date:desc',
        'pagination[pageSize]': '50',
        'populate': 'doctor',
      };
      if (type != null && type != 'all') {
        params['filters[type][\$eq]'] = type;
      }

      final response = await _dio.get('/medical-records', queryParameters: params);
      final raw = response.data;
      List<dynamic> items = [];
      if (raw is Map && raw['data'] is List) {
        items = raw['data'] as List;
      } else if (raw is List) {
        items = raw;
      }
      return items.map((e) => MedicalRecordModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw parseDioError(e);
    }
  }

  Future<List<MedicalRecordModel>> getByPatient(int patientId) async {
    try {
      final response = await _dio.get('/medical-records', queryParameters: {
        'filters[patient][id][\$eq]': patientId,
        'sort': 'date:desc',
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
      return items.map((e) => MedicalRecordModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw parseDioError(e);
    }
  }

  Future<MedicalRecordModel> createRecord(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/medical-records', data: {'data': data});
      final raw = response.data;
      final item = raw is Map && raw['data'] != null ? raw['data'] : raw;
      return MedicalRecordModel.fromJson(item as Map<String, dynamic>);
    } catch (e) {
      throw parseDioError(e);
    }
  }
}

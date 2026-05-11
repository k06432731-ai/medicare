import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicare/core/network/dio_client.dart';
import 'package:medicare/features/doctor/data/models/doctor_model.dart';

final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepository(ref.read(dioClientProvider));
});

class DoctorRepository {
  final Dio _dio;

  DoctorRepository(this._dio);

  Future<List<DoctorModel>> getDoctors({String? specialty}) async {
    try {
      final Map<String, dynamic> params = {
        'filters[appRole][\$eq]': 'doctor',
        'filters[isAvailable][\$eq]': true,
        'populate': 'avatar',
        'pagination[pageSize]': '50',
      };
      if (specialty != null && specialty.isNotEmpty) {
        params['filters[specialty][\$containsi]'] = specialty;
      }

      final response = await _dio.get('/users', queryParameters: params);
      final List<dynamic> data = response.data is List ? response.data : [];
      return data.map((e) => DoctorModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw parseDioError(e);
    }
  }

  Future<DoctorModel> getDoctorById(int id) async {
    try {
      final response = await _dio.get('/users/$id', queryParameters: {'populate': 'avatar'});
      return DoctorModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw parseDioError(e);
    }
  }

  /// Récupère uniquement les spécialités des médecins actifs.
  /// Optimisé : ne charge que le champ specialty (pas d'avatar, pas de données lourdes).
  Future<List<String>> getSpecialties() async {
    try {
      final response = await _dio.get('/users', queryParameters: {
        'filters[appRole][\$eq]': 'doctor',
        'filters[isAvailable][\$eq]': true,
        'fields[0]': 'specialty',
        'pagination[pageSize]': '200',
      });
      final List<dynamic> data =
          response.data is List ? response.data as List : [];
      final specialties = data
          .map((e) => e['specialty'] as String?)
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      return specialties;
    } catch (e) {
      return [];
    }
  }
}

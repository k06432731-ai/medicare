import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicare/core/network/dio_client.dart';
import 'package:medicare/features/appointment/data/models/appointment_model.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(ref.read(dioClientProvider));
});

class AppointmentRepository {
  final dynamic _dio;

  AppointmentRepository(this._dio);

  Future<List<AppointmentModel>> getMyAppointments({String? status}) async {
    try {
      final Map<String, dynamic> params = {
        'populate': 'doctor,doctor.avatar,patient',
        'sort': 'appointmentDate:desc',
        'pagination[pageSize]': '50',
      };
      if (status != null && status != 'all') {
        params['status'] = status;
      }

      final response = await _dio.get('/appointments', queryParameters: params);
      final raw = response.data;
      List<dynamic> items = [];
      if (raw is Map && raw['data'] is List) {
        items = raw['data'] as List;
      } else if (raw is List) {
        items = raw;
      }
      return items.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw parseDioError(e);
    }
  }

  Future<AppointmentModel> createAppointment({
    required int doctorId,
    required DateTime appointmentDate,
    required String reason,
    required AppointmentType type,
    String? notes,
  }) async {
    try {
      final response = await _dio.post('/appointments', data: {
        'data': {
          'doctor': doctorId,
          'appointmentDate': appointmentDate.toIso8601String(),
          'reason': reason,
          'type': type.apiValue,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      });
      final raw = response.data;
      final item = raw is Map && raw['data'] != null ? raw['data'] : raw;
      return AppointmentModel.fromJson(item as Map<String, dynamic>);
    } catch (e) {
      throw parseDioError(e);
    }
  }

  Future<AppointmentModel> cancelAppointment(int id) async {
    try {
      final response = await _dio.put('/appointments/$id', data: {
        'data': {'status': 'cancelled'},
      });
      final raw = response.data;
      final item = raw is Map && raw['data'] != null ? raw['data'] : raw;
      return AppointmentModel.fromJson(item as Map<String, dynamic>);
    } catch (e) {
      throw parseDioError(e);
    }
  }

  Future<AppointmentModel> updateAppointmentStatus(
    int id,
    String status, {
    String? doctorNotes,
  }) async {
    try {
      final response = await _dio.put('/appointments/$id', data: {
        'data': {
          'status': status,
          // ignore: use_null_aware_elements
          if (doctorNotes != null) 'doctorNotes': doctorNotes,
        },
      });
      final raw = response.data;
      final item = raw is Map && raw['data'] != null ? raw['data'] : raw;
      return AppointmentModel.fromJson(item as Map<String, dynamic>);
    } catch (e) {
      throw parseDioError(e);
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicare/core/network/dio_client.dart';
import '../models/lab_order_model.dart';

final labOrderRepositoryProvider =
    Provider<LabOrderRepository>((ref) {
  return LabOrderRepository(ref.read(dioClientProvider));
});

class LabOrderRepository {
  final dynamic _dio;
  LabOrderRepository(this._dio);

  static const _populate =
      'laboratory,patient,doctor';

  Future<List<LabOrderModel>> getMyOrders() async {
    try {
      final res = await _dio.get('/lab-orders', queryParameters: {
        'sort': 'orderedAt:desc',
        'pagination[pageSize]': '50',
        'populate': _populate,
      });
      return _parse(res.data);
    } catch (e) {
      throw parseDioError(e);
    }
  }

  Future<List<LabOrderModel>> getByPatient(int patientId) async {
    try {
      final res = await _dio.get('/lab-orders', queryParameters: {
        'patientId': patientId,
        'sort': 'orderedAt:desc',
        'pagination[pageSize]': '50',
        'populate': _populate,
      });
      return _parse(res.data);
    } catch (e) {
      throw parseDioError(e);
    }
  }

  Future<LabOrderModel> createOrder(Map<String, dynamic> data) async {
    try {
      final res =
          await _dio.post('/lab-orders', data: {'data': data});
      final raw = res.data;
      final item =
          raw is Map && raw['data'] != null ? raw['data'] : raw;
      return LabOrderModel.fromJson(item as Map<String, dynamic>);
    } catch (e) {
      throw parseDioError(e);
    }
  }

  List<LabOrderModel> _parse(dynamic raw) {
    List<dynamic> items = [];
    if (raw is Map && raw['data'] is List) {
      items = raw['data'] as List;
    } else if (raw is List) {
      items = raw;
    }
    return items
        .map((e) => LabOrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicare/core/network/dio_client.dart';
import '../models/invoice_model.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository(ref.read(dioClientProvider));
});

class InvoiceRepository {
  final dynamic _dio;
  InvoiceRepository(this._dio);

  Future<List<InvoiceModel>> getMyInvoices() async {
    try {
      final res = await _dio.get('/invoices', queryParameters: {
        'sort': 'createdAt:desc',
        'pagination[pageSize]': '50',
        'populate': 'doctor,appointment,labOrder',
      });
      return _parse(res.data);
    } catch (e) {
      throw parseDioError(e);
    }
  }

  Future<List<InvoiceModel>> getByPatient(int patientId) async {
    try {
      final res = await _dio.get('/invoices', queryParameters: {
        'patientId': patientId,
        'sort': 'createdAt:desc',
        'pagination[pageSize]': '50',
        'populate': 'doctor,appointment,labOrder',
      });
      return _parse(res.data);
    } catch (e) {
      throw parseDioError(e);
    }
  }

  Future<InvoiceModel> createInvoice(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/invoices', data: {'data': data});
      final raw = res.data;
      final item = raw is Map && raw['data'] != null ? raw['data'] : raw;
      return InvoiceModel.fromJson(item as Map<String, dynamic>);
    } catch (e) {
      throw parseDioError(e);
    }
  }

  Future<InvoiceModel> payInvoice(
      int id, PaymentMethod method) async {
    try {
      final res = await _dio.put('/invoices/$id', data: {
        'data': {
          'status': 'paid',
          'paymentMethod': method.apiValue,
          'paidAt': DateTime.now().toIso8601String(),
        },
      });
      final raw = res.data;
      final item = raw is Map && raw['data'] != null ? raw['data'] : raw;
      return InvoiceModel.fromJson(item as Map<String, dynamic>);
    } catch (e) {
      throw parseDioError(e);
    }
  }

  List<InvoiceModel> _parse(dynamic raw) {
    List<dynamic> items = [];
    if (raw is Map && raw['data'] is List) {
      items = raw['data'] as List;
    } else if (raw is List) {
      items = raw;
    }
    return items
        .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicare/core/network/dio_client.dart';
import '../models/laboratory_model.dart';

final laboratoryRepositoryProvider =
    Provider<LaboratoryRepository>((ref) {
  return LaboratoryRepository(ref.read(dioClientProvider));
});

class LaboratoryRepository {
  final dynamic _dio;
  LaboratoryRepository(this._dio);

  Future<List<LaboratoryModel>> getLaboratories({LabType? type}) async {
    try {
      final Map<String, dynamic> params = {
        'filters[isActive][\$eq]': true,
        'sort': 'name:asc',
        'pagination[pageSize]': '100',
      };
      if (type != null) params['filters[type][\$eq]'] = type.apiValue;

      final res = await _dio.get('/laboratories', queryParameters: params);
      final raw = res.data;
      List<dynamic> items = [];
      if (raw is Map && raw['data'] is List) {
        items = raw['data'] as List;
      } else if (raw is List) {
        items = raw;
      }
      return items
          .map((e) => LaboratoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw parseDioError(e);
    }
  }
}

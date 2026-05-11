// Unit test for PrescriptionRepository.
//
// Verifies that filter query parameters are built in the Strapi v5 format
// (filters[status][$eq]=active) when calling getMyPrescriptions(status: 'active').
//
// We avoid adding mockito/mocktail as new dependencies and instead override
// Dio's HttpClientAdapter with a tiny manual implementation that captures the
// request and returns a canned response.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicare/features/prescription/data/repositories/prescription_repository.dart';

/// Captures the last request that went through Dio and returns a fixed
/// response. We implement [HttpClientAdapter] manually to keep dependencies
/// minimal.
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;
  Object responseBody;

  // ignore: unused_element_parameter
  _CapturingAdapter({this.responseBody = const {'data': <dynamic>[]}});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    final bytes = utf8.encode(jsonEncode(responseBody));
    return ResponseBody.fromBytes(
      bytes,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('PrescriptionRepository.getMyPrescriptions', () {
    late Dio dio;
    late _CapturingAdapter adapter;
    late PrescriptionRepository repo;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:1337/api'));
      adapter = _CapturingAdapter();
      dio.httpClientAdapter = adapter;
      repo = PrescriptionRepository(dio);
    });

    test('builds the Strapi v5 filter param filters[status][\$eq]=active',
        () async {
      await repo.getMyPrescriptions(status: 'active');

      final req = adapter.lastRequest;
      expect(req, isNotNull);
      expect(req!.path, '/prescriptions');

      final params = req.queryParameters;
      expect(params['filters[status][\$eq]'], 'active');
      expect(params['sort'], 'issuedDate:desc');
      expect(params['pagination[pageSize]'], '50');
      expect(params['populate'], 'doctor');
    });

    test('omits the status filter when status is null', () async {
      await repo.getMyPrescriptions();

      final params = adapter.lastRequest!.queryParameters;
      expect(params.containsKey('filters[status][\$eq]'), isFalse);
    });

    test('omits the status filter when status is "all"', () async {
      await repo.getMyPrescriptions(status: 'all');

      final params = adapter.lastRequest!.queryParameters;
      expect(params.containsKey('filters[status][\$eq]'), isFalse);
    });

    test('returns an empty list when the response has no data', () async {
      final result = await repo.getMyPrescriptions(status: 'active');
      expect(result, isEmpty);
    });
  });
}

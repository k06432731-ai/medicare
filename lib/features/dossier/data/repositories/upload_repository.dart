import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicare/core/network/dio_client.dart';

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  return UploadRepository(ref.watch(dioClientProvider));
});

/// Résultat d'un upload Strapi (endpoint POST /upload)
class UploadedFile {
  final int id;
  final String name;
  final String url;
  final String mime;
  final int size; // en bytes

  const UploadedFile({
    required this.id,
    required this.name,
    required this.url,
    required this.mime,
    required this.size,
  });

  factory UploadedFile.fromJson(Map<String, dynamic> json) {
    return UploadedFile(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      mime: json['mime'] as String? ?? '',
      size: (json['size'] as num? ?? 0).toInt(),
    );
  }

  /// Taille lisible (ex: 1.2 Mo)
  String get sizeLabel {
    if (size < 1024) return '$size o';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} Ko';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
}

class UploadRepository {
  final Dio _dio;
  UploadRepository(this._dio);

  /// Upload un fichier vers Strapi Media Library (POST /upload).
  /// Retourne l'objet [UploadedFile] créé.
  Future<UploadedFile> uploadFile(File file, {String? refId, String? ref, String? field}) async {
    try {
      final formData = FormData.fromMap({
        'files': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
        if (refId != null) 'refId': refId,
        if (ref != null) 'ref': ref,
        if (field != null) 'field': field,
      });

      final res = await _dio.post('/upload', data: formData);
      final list = res.data as List;
      return UploadedFile.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}

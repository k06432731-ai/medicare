import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioClientProvider),
    storage: ref.watch(secureStorageProvider),
  );
});

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository({required Dio dio, required FlutterSecureStorage storage})
      : _dio = dio,
        _storage = storage;

  // ── Auth calls ──────────────────────────────────────────────────────────────

  Future<AuthResponseModel> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'identifier': email, 'password': password},
      );
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<AuthResponseModel> register(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.register, data: data);
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<UserModel> getMe() async {
    try {
      // populate=role fetches the Users-Permissions role object
      final response = await _dio.get(ApiConstants.me, queryParameters: {
        'populate[0]': 'role',
        'populate[1]': 'avatar',
      });
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/users/me', data: data);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  /// Uploads an image file to Strapi media and links it as the user's avatar.
  /// Returns the new avatar URL.
  Future<String> uploadAvatar(String filePath) async {
    try {
      // 1. Upload to Strapi media library
      final formData = FormData.fromMap({
        'files': await MultipartFile.fromFile(
          filePath,
          filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });
      final uploadRes = await _dio.post('/upload', data: formData);
      final fileId = (uploadRes.data as List).first['id'] as int;
      final fileUrl = (uploadRes.data as List).first['url'] as String? ?? '';

      // 2. Link the uploaded file to the user profile
      await _dio.put('/users/me', data: {'avatar': fileId});

      return fileUrl;
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  /// Register this device's FCM push token with the backend.
  /// Saves it on the current user record so the backend can target pushes.
  Future<void> registerFcmToken(String token) async {
    try {
      await _dio.post(
        '/notification-engine/register-fcm-token',
        data: {'token': token},
      );
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'password': newPassword,
          'passwordConfirmation': newPassword,
        },
      );
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── Secure storage ──────────────────────────────────────────────────────────

  Future<void> saveSession({
    required String token,
    required int userId,
    required String role,
  }) async {
    await Future.wait([
      _storage.write(key: ApiConstants.tokenKey, value: token),
      _storage.write(key: ApiConstants.userIdKey, value: userId.toString()),
      _storage.write(key: ApiConstants.userRoleKey, value: role),
    ]);
  }

  Future<String?> getStoredToken() => _storage.read(key: ApiConstants.tokenKey);

  Future<String?> getStoredRole() => _storage.read(key: ApiConstants.userRoleKey);

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: ApiConstants.tokenKey),
      _storage.delete(key: ApiConstants.userIdKey),
      _storage.delete(key: ApiConstants.userRoleKey),
    ]);
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

/// Provider for the Dio instance.
/// The 401 interceptor calls [_logoutCallback] which is set by the auth layer
/// after the Dio client is created (avoids circular dependency at build time).
final dioClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // ── JWT injection ────────────────────────────────────────────────────────────
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: ApiConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          // Session expired → clear stored credentials and let the router
          // redirect to login.  We avoid calling authProvider here to prevent
          // a circular provider dependency; instead we clear storage directly.
          await storage.delete(key: ApiConstants.tokenKey);
          await storage.delete(key: ApiConstants.userIdKey);
          await storage.delete(key: ApiConstants.userRoleKey);
          // Notify any listener that cares (authProvider watches storage on
          // startup, but for mid-session logout we rely on a ProviderObserver
          // or the router notifier which is driven by authProvider).
          // A simple approach: invalidate authProvider so it re-checks.
          // We use a post-frame callback via a global logout hook.
          _on401?.call();
        }
        handler.next(error);
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
        logPrint: (o) => debugPrint('[DIO] $o'),
      ),
    );
  }

  return dio;
});

// ── 401 logout hook ───────────────────────────────────────────────────────────
// Set once in app.dart after ProviderScope is available.
// Calling it triggers authProvider.notifier.logout() without a circular dep.

VoidCallback? _on401;

void registerOn401Hook(VoidCallback cb) => _on401 = cb;

/// Converts a Dio error (or any exception) to an [AppException]
AppException parseDioError(Object e) {
  if (e is! DioException) return AppException(e.toString());

  if (e.response != null) {
    final data = e.response!.data;
    String message = 'Une erreur est survenue';

    if (data is Map) {
      // Strapi v5 error format: { error: { message: "..." } }
      final errorObj = data['error'];
      if (errorObj is Map && errorObj['message'] is String) {
        message = errorObj['message'] as String;
      }
      // Strapi v3 format
      else if (data['message'] is List) {
        final msgs = data['message'] as List;
        if (msgs.isNotEmpty && msgs.first is Map) {
          final messages = msgs.first['messages'] as List?;
          if (messages != null && messages.isNotEmpty) {
            message = messages.first['id'] as String? ?? message;
          }
        }
      }
    }

    final statusCode = e.response!.statusCode;
    if (statusCode == 401) return UnauthorizedException();
    if (statusCode == 400) return ValidationException(message);
    return AppException(message, statusCode: statusCode);
  }

  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return const NetworkException('Délai de connexion dépassé.');
  }

  if (e.type == DioExceptionType.connectionError) {
    return const NetworkException(
        'Impossible de joindre le serveur. Vérifiez votre réseau.');
  }

  return const AppException('Une erreur inattendue est survenue.');
}

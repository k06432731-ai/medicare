import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/fcm_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';
import 'auth_state.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthChecking()) {
    _checkStoredSession();
  }

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> _checkStoredSession() async {
    try {
      final token = await _repository.getStoredToken();
      if (token == null) {
        state = const AuthUnauthenticated();
        return;
      }
      final user = await _repository.getMe();
      state = AuthAuthenticated(user);
    } catch (_) {
      await _repository.clearSession();
      state = const AuthUnauthenticated();
    }
  }

  // ── Public actions ──────────────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final response = await _repository.login(email, password);
      await _repository.saveSession(
        token: response.jwt,
        userId: response.user.id,
        role: response.user.role,
      );
      state = AuthAuthenticated(response.user);
      // Register FCM token with backend (best-effort, non-blocking)
      FcmService.registerWithBackend(_repository.registerFcmToken);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    state = const AuthLoading();
    try {
      final response = await _repository.register(data);
      await _repository.saveSession(
        token: response.jwt,
        userId: response.user.id,
        role: response.user.role,
      );
      state = AuthAuthenticated(response.user);
      // Register FCM token with backend (best-effort, non-blocking)
      FcmService.registerWithBackend(_repository.registerFcmToken);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    await _repository.clearSession();
    state = const AuthUnauthenticated();
  }

  void clearError() {
    if (state is AuthError) state = const AuthUnauthenticated();
  }

  /// Change password via Strapi /auth/change-password.
  /// Throws [AppException] on failure — caller handles the error.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  void updateUser(UserModel user) {
    if (state is AuthAuthenticated) state = AuthAuthenticated(user);
  }

  UserModel? get currentUser {
    final s = state;
    return s is AuthAuthenticated ? s.user : null;
  }
}

import '../data/models/user_model.dart';

sealed class AuthState {
  const AuthState();
}

/// Initial state — checking stored token
class AuthChecking extends AuthState {
  const AuthChecking();
}

/// User is authenticated
class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
}

/// No valid session
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// An auth operation is in progress (login / register)
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// An auth operation failed
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

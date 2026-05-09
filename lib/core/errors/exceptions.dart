class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Problème de connexion. Vérifiez votre réseau.']);
}

class ServerException extends AppException {
  const ServerException([super.message = 'Erreur serveur. Réessayez plus tard.', int? statusCode])
      : super(statusCode: statusCode);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException()
      : super('Session expirée. Veuillez vous reconnecter.', statusCode: 401);
}

class ValidationException extends AppException {
  const ValidationException(super.message) : super(statusCode: 400);
}

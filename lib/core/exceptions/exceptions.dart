/// ─── Bamako Thrift — Exceptions (Data Layer) ─────────────────────────────
/// Les exceptions sont levées dans la couche data et converties en Failure
/// dans la couche domain (repositories).

class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const AppException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'AppException: $message (code: $statusCode)';
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Erreur réseau',
    super.statusCode,
    super.data,
  });
}

class NoInternetException extends AppException {
  const NoInternetException({
    super.message = 'Pas de connexion internet',
    super.statusCode,
    super.data,
  });
}

class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'La requête a expiré',
    super.statusCode,
    super.data,
  });
}

class ServerException extends AppException {
  const ServerException({
    super.message = 'Erreur serveur interne',
    super.statusCode = 500,
    super.data,
  });
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Non autorisé – veuillez vous reconnecter',
    super.statusCode = 401,
    super.data,
  });
}

class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'Accès refusé',
    super.statusCode = 403,
    super.data,
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Ressource introuvable',
    super.statusCode = 404,
    super.data,
  });
}

class ValidationException extends AppException {
  final Map<String, dynamic>? errors;
  const ValidationException({
    required super.message,
    super.statusCode = 422,
    this.errors,
    super.data,
  });
}

class FirebaseAuthException extends AppException {
  final String? code;
  const FirebaseAuthException({
    required super.message,
    this.code,
    super.statusCode,
    super.data,
  });
}

class CacheException extends AppException {
  const CacheException({
    super.message = 'Erreur de cache',
    super.statusCode,
    super.data,
  });
}

class UnexpectedException extends AppException {
  const UnexpectedException({
    super.message = 'Une erreur inattendue est survenue',
    super.statusCode,
    super.data,
  });
}

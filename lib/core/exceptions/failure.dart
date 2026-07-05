/// ─── Bamako Thrift — Failures (Domain Layer) ──────────────────────────────
import 'package:equatable/equatable.dart';

/// Classe de base pour toutes les erreurs fonctionnelles (domain layer).
/// Utiliser les sous-classes pour identifier précisément l'origine.
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];

  @override
  String toString() => '$runtimeType(message: $message, statusCode: $statusCode)';
}

// ── Réseau ─────────────────────────────────────────────────────────────────
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Erreur de connexion', super.statusCode});
}

class ConnectionFailure extends Failure {
  const ConnectionFailure({super.message = 'Pas de connexion internet', super.statusCode});
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({super.message = 'La requête a expiré', super.statusCode});
}

// ── Serveur ────────────────────────────────────────────────────────────────
class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Erreur serveur', super.statusCode});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'Non autorisé', super.statusCode = 401});
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure({super.message = 'Accès refusé', super.statusCode = 403});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'Ressource introuvable', super.statusCode = 404});
}

class ConflictFailure extends Failure {
  const ConflictFailure({super.message = 'Conflit de données', super.statusCode = 409});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.statusCode = 422});
}

// ── Firebase ───────────────────────────────────────────────────────────────
class FirebaseFailure extends Failure {
  final String? code;
  const FirebaseFailure({required super.message, this.code, super.statusCode});

  @override
  List<Object?> get props => [...super.props, code];
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.statusCode});
}

class FirestoreFailure extends Failure {
  const FirestoreFailure({required super.message, super.statusCode});
}

class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.statusCode});
}

// ── Cache / Stockage local ─────────────────────────────────────────────────
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Erreur de cache local', super.statusCode});
}

class StorageLocalFailure extends Failure {
  const StorageLocalFailure({super.message = 'Erreur de stockage', super.statusCode});
}

// ── Métier ─────────────────────────────────────────────────────────────────
class BusinessFailure extends Failure {
  const BusinessFailure({required super.message, super.statusCode});
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.message = 'Une erreur inattendue est survenue', super.statusCode});
}

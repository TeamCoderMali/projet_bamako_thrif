// ─── Bamako Thrift — Use Case Base ─────────────────────────────────────────
// Classe abstraite générique pour tous les use cases (Clean Architecture).
// Params = type des paramètres d'entrée, Result = type du résultat.

abstract class UseCase<Result, Params> {
  Future<Result> call(Params params);
}

/// Use case sans paramètres.
abstract class UseCaseNoParams<Result> {
  Future<Result> call();
}

/// Use case retournant un Stream.
abstract class StreamUseCase<Result, Params> {
  Stream<Result> call(Params params);
}

/// Classe marqueur pour les use cases sans paramètres.
class NoParams {
  const NoParams();
}

// ─── Bamako Thrift — Sign In UseCase ──────────────────────────────────────
import '../../../../core/utils/use_case.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmailUseCase extends UseCase<UserEntity, SignInParams> {
  final AuthRepository _repository;
  SignInWithEmailUseCase(this._repository);

  @override
  Future<UserEntity> call(SignInParams params) {
    return _repository.signInWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}

class SignInParams {
  final String email;
  final String password;
  const SignInParams({required this.email, required this.password});
}

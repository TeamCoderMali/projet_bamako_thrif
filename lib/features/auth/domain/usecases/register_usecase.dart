// ─── Bamako Thrift — Register UseCase ─────────────────────────────────────
import '../../../../core/utils/use_case.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterWithEmailUseCase extends UseCase<UserEntity, RegisterParams> {
  final AuthRepository _repository;
  RegisterWithEmailUseCase(this._repository);

  @override
  Future<UserEntity> call(RegisterParams params) {
    return _repository.registerWithEmail(
      email: params.email,
      password: params.password,
      fullName: params.fullName,
      phoneNumber: params.phoneNumber,
    );
  }
}

class RegisterParams {
  final String email;
  final String password;
  final String fullName;
  final String? phoneNumber;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.fullName,
    this.phoneNumber,
  });
}

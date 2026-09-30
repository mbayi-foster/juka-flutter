import 'package:juka/features/auth/domain/entities/app_user.dart';
import 'package:juka/features/auth/domain/repositories/auth_repository.dart';

/// Création d'un compte avec une adresse e-mail et un mot de passe.
class SignUpWithEmailUseCase {
  const SignUpWithEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) {
    return _repository.signUpWithEmail(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
  }
}

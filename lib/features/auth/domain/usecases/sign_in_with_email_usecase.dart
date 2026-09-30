import 'package:juka/features/auth/domain/entities/app_user.dart';
import 'package:juka/features/auth/domain/repositories/auth_repository.dart';

/// Connexion avec une adresse e-mail et un mot de passe.
class SignInWithEmailUseCase {
  const SignInWithEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({required String email, required String password}) {
    return _repository.signInWithEmail(email: email, password: password);
  }
}

import 'package:juka/features/auth/domain/entities/app_user.dart';
import 'package:juka/features/auth/domain/enums/google_auth_mode.dart';
import 'package:juka/features/auth/domain/repositories/auth_repository.dart';

/// Connexion ou inscription via le compte Google de l'utilisateur.
class SignInWithGoogleUseCase {
  const SignInWithGoogleUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({required GoogleAuthMode mode}) {
    return _repository.signInWithGoogle(mode: mode);
  }
}

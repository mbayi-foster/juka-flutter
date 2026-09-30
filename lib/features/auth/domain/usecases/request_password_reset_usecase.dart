import 'package:juka/features/auth/domain/repositories/auth_repository.dart';

/// Demande d'envoi d'un lien de réinitialisation du mot de passe.
class RequestPasswordResetUseCase {
  const RequestPasswordResetUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String email}) {
    return _repository.requestPasswordReset(email: email);
  }
}

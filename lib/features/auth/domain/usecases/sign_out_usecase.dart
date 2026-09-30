import 'package:juka/features/auth/domain/repositories/auth_repository.dart';

/// Ferme la session de l'utilisateur courant.
class SignOutUseCase {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.signOut();
}

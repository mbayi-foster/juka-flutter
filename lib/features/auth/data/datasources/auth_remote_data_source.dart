import 'package:juka/features/auth/data/exceptions/auth_exception.dart';
import 'package:juka/features/auth/data/models/user_model.dart';
import 'package:juka/features/auth/domain/enums/google_auth_mode.dart';

/// Source de données distante pour l'authentification.
abstract interface class AuthRemoteDataSource {
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  });

  Future<UserModel> signInWithGoogle({required GoogleAuthMode mode});

  Future<void> requestPasswordReset({required String email});

  Future<void> signOut();
}

/// Implémentation locale (simulation de l'API `api-juka`).
///
/// Elle permet de faire tourner l'application sans backend. Lorsque les
/// endpoints NestJS seront disponibles, il suffira de remplacer le corps des
/// méthodes par les appels HTTP (Dio/HttpClient) et de lever une
/// [AuthException] en cas d'échec : le reste des couches est inchangé.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl();

  /// Latence simulée pour rendre les états de chargement visibles.
  static const Duration _latency = Duration(milliseconds: 900);

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // TODO(api): POST /auth/login { email, password }
    await Future<void>.delayed(_latency);
    return _buildUser(email: email);
  }

  @override
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    // TODO(api): POST /auth/register { email, password, firstName, lastName }
    await Future<void>.delayed(_latency);
    return _buildUser(email: email, firstName: firstName, lastName: lastName);
  }

  @override
  Future<UserModel> signInWithGoogle({required GoogleAuthMode mode}) async {
    // TODO(api): échange du jeton Google — POST /auth/google
    await Future<void>.delayed(_latency);
    return _buildUser(
      email: 'utilisateur.google@gmail.com',
      firstName: 'Utilisateur',
      lastName: 'Google',
      emailVerified: true,
    );
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    // TODO(api): POST /auth/password/forgot { email }
    await Future<void>.delayed(_latency);
  }

  @override
  Future<void> signOut() async {
    // TODO(api): POST /auth/logout
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  UserModel _buildUser({
    required String email,
    String? firstName,
    String? lastName,
    bool emailVerified = false,
  }) {
    return UserModel(
      id: email.hashCode.toUnsigned(32).toRadixString(16),
      email: email,
      firstName: firstName,
      lastName: lastName,
      emailVerified: emailVerified,
    );
  }
}

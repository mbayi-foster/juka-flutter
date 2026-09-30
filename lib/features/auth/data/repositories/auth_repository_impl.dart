import 'package:juka/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:juka/features/auth/data/exceptions/auth_exception.dart';
import 'package:juka/features/auth/data/models/user_model.dart';
import 'package:juka/features/auth/domain/entities/app_user.dart';
import 'package:juka/features/auth/domain/enums/google_auth_mode.dart';
import 'package:juka/features/auth/domain/failures/auth_failure.dart';
import 'package:juka/features/auth/domain/repositories/auth_repository.dart';

/// Implémentation du contrat [AuthRepository] au-dessus de la source distante.
///
/// Elle traduit les [AuthException] techniques en [AuthFailure] métier.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  static const String _unexpectedMessage =
      'Une erreur inattendue est survenue. Veuillez réessayer.';

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _guard(
      () => _remoteDataSource.signInWithEmail(email: email, password: password),
    );
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) {
    return _guard(
      () => _remoteDataSource.signUpWithEmail(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      ),
    );
  }

  @override
  Future<AppUser> signInWithGoogle({required GoogleAuthMode mode}) {
    return _guard(() => _remoteDataSource.signInWithGoogle(mode: mode));
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    try {
      await _remoteDataSource.requestPasswordReset(email: email);
    } on AuthException catch (exception) {
      throw AuthFailure(exception.message);
    } catch (_) {
      throw const AuthFailure(_unexpectedMessage);
    }
  }

  @override
  Future<void> signOut() => _remoteDataSource.signOut();

  /// Exécute [action] et convertit les erreurs techniques en [AuthFailure].
  Future<AppUser> _guard(Future<UserModel> Function() action) async {
    try {
      final model = await action();
      return model.toEntity();
    } on AuthException catch (exception) {
      throw AuthFailure(exception.message);
    } catch (_) {
      throw const AuthFailure(_unexpectedMessage);
    }
  }
}

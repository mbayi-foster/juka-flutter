import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:juka/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:juka/features/auth/domain/entities/app_user.dart';
import 'package:juka/features/auth/domain/enums/google_auth_mode.dart';
import 'package:juka/features/auth/domain/failures/auth_failure.dart';
import 'package:juka/features/auth/domain/repositories/auth_repository.dart';
import 'package:juka/features/auth/domain/usecases/request_password_reset_usecase.dart';
import 'package:juka/features/auth/domain/usecases/sign_in_with_email_usecase.dart';
import 'package:juka/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:juka/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:juka/features/auth/domain/usecases/sign_up_with_email_usecase.dart';
import 'package:juka/features/auth/presentation/state/auth_state.dart';

// ---------------------------------------------------------------------------
// Injection des dépendances (data -> domain)
// ---------------------------------------------------------------------------

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => const AuthRemoteDataSourceImpl(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider)),
);

final signInWithEmailUseCaseProvider = Provider<SignInWithEmailUseCase>(
  (ref) => SignInWithEmailUseCase(ref.watch(authRepositoryProvider)),
);

final signUpWithEmailUseCaseProvider = Provider<SignUpWithEmailUseCase>(
  (ref) => SignUpWithEmailUseCase(ref.watch(authRepositoryProvider)),
);

final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase>(
  (ref) => SignInWithGoogleUseCase(ref.watch(authRepositoryProvider)),
);

final requestPasswordResetUseCaseProvider =
    Provider<RequestPasswordResetUseCase>(
      (ref) => RequestPasswordResetUseCase(ref.watch(authRepositoryProvider)),
    );

final signOutUseCaseProvider = Provider<SignOutUseCase>(
  (ref) => SignOutUseCase(ref.watch(authRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// Contrôleur
// ---------------------------------------------------------------------------

/// Pilote les cas d'usage d'authentification et expose l'état aux écrans.
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  static const String _unexpectedMessage =
      'Une erreur inattendue est survenue. Veuillez réessayer.';

  @override
  AuthState build() => const AuthState();

  /// Connexion par e-mail. Retourne `null` en cas de succès, sinon le message
  /// d'erreur à afficher.
  Future<String?> signIn({required String email, required String password}) {
    return _authenticate(
      () => ref.read(signInWithEmailUseCaseProvider)(
        email: email,
        password: password,
      ),
    );
  }

  /// Création de compte par e-mail.
  Future<String?> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) {
    return _authenticate(
      () => ref.read(signUpWithEmailUseCaseProvider)(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      ),
    );
  }

  /// Connexion ou inscription via Google.
  Future<String?> signInWithGoogle(GoogleAuthMode mode) {
    return _authenticate(
      () => ref.read(signInWithGoogleUseCaseProvider)(mode: mode),
    );
  }

  /// Demande de réinitialisation du mot de passe.
  Future<String?> requestPasswordReset({required String email}) async {
    state = AuthState(status: AuthStatus.submitting, user: state.user);
    try {
      await ref.read(requestPasswordResetUseCaseProvider)(email: email);
      state = AuthState(status: AuthStatus.success, user: state.user);
      return null;
    } on AuthFailure catch (failure) {
      state = AuthState(
        status: AuthStatus.failure,
        user: state.user,
        errorMessage: failure.message,
      );
      return failure.message;
    } catch (_) {
      state = AuthState(
        status: AuthStatus.failure,
        user: state.user,
        errorMessage: _unexpectedMessage,
      );
      return _unexpectedMessage;
    }
  }

  Future<void> signOut() async {
    await ref.read(signOutUseCaseProvider)();
    state = const AuthState();
  }

  Future<String?> _authenticate(Future<AppUser> Function() action) async {
    state = const AuthState(status: AuthStatus.submitting);
    try {
      final user = await action();
      state = AuthState(status: AuthStatus.success, user: user);
      return null;
    } on AuthFailure catch (failure) {
      state = AuthState(
        status: AuthStatus.failure,
        errorMessage: failure.message,
      );
      return failure.message;
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.failure,
        errorMessage: _unexpectedMessage,
      );
      return _unexpectedMessage;
    }
  }
}

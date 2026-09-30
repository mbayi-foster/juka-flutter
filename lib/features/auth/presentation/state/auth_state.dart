import 'package:juka/features/auth/domain/entities/app_user.dart';

/// État du cycle d'authentification.
enum AuthStatus {
  /// Aucune action en cours.
  idle,

  /// Une requête est en cours (formulaire en chargement).
  submitting,

  /// La dernière action a réussi.
  success,

  /// La dernière action a échoué.
  failure,
}

/// État exposé par `authControllerProvider`.
class AuthState {
  const AuthState({
    this.status = AuthStatus.idle,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;

  /// Utilisateur connecté, `null` en cas de déconnexion.
  final AppUser? user;

  /// Dernier message d'erreur affichable, `null` si tout va bien.
  final String? errorMessage;

  bool get isSubmitting => status == AuthStatus.submitting;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

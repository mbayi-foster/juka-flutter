import 'package:juka/features/auth/domain/entities/app_user.dart';
import 'package:juka/features/auth/domain/enums/google_auth_mode.dart';

/// Contrat du domaine pour l'authentification.
///
/// L'implémentation concrète vit dans la couche `data` : le domaine ne sait
/// pas si les données viennent de l'API, d'un cache ou d'un service tiers.
abstract interface class AuthRepository {
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  });

  /// Authentification (ou création de compte) via Google.
  Future<AppUser> signInWithGoogle({required GoogleAuthMode mode});

  /// Envoie un lien de réinitialisation à [email].
  Future<void> requestPasswordReset({required String email});

  Future<void> signOut();
}

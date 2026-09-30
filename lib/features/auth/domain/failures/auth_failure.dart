/// Erreur métier remontée par la couche domaine.
///
/// Le message est directement affichable à l'utilisateur.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthFailure: $message';
}

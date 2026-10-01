/// Erreur métier remontée par la couche domaine du patrimoine.
///
/// Le message est directement affichable à l'utilisateur.
class WealthFailure implements Exception {
  const WealthFailure(this.message);

  final String message;

  @override
  String toString() => 'WealthFailure: $message';
}

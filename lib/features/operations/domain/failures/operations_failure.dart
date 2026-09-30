/// Erreur métier remontée par la couche domaine des opérations.
///
/// Le message est directement affichable à l'utilisateur.
class OperationsFailure implements Exception {
  const OperationsFailure(this.message);

  final String message;

  @override
  String toString() => 'OperationsFailure: $message';
}

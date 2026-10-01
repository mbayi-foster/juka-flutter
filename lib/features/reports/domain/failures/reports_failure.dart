/// Erreur métier remontée par la couche domaine des rapports.
///
/// Le message est directement affichable à l'utilisateur.
class ReportsFailure implements Exception {
  const ReportsFailure(this.message);

  final String message;

  @override
  String toString() => 'ReportsFailure: $message';
}

/// Erreur métier remontée par la couche domaine du tableau de bord.
///
/// Le message est directement affichable à l'utilisateur.
class DashboardFailure implements Exception {
  const DashboardFailure(this.message);

  final String message;

  @override
  String toString() => 'DashboardFailure: $message';
}

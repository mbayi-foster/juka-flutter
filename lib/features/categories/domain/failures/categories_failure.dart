/// Erreur métier remontée par la couche domaine des catégories et budgets.
///
/// Le message est directement affichable à l'utilisateur.
class CategoriesFailure implements Exception {
  const CategoriesFailure(this.message);

  final String message;

  @override
  String toString() => 'CategoriesFailure: $message';
}

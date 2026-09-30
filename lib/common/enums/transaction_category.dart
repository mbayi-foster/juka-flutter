/// Catégories d'opérations financières, partagées par tous les écrans.
///
/// L'énumération ne dépend volontairement pas de Flutter : l'icône et la
/// couleur associées sont définies dans `CategoryVisuals` (couche common).
enum TransactionCategory {
  housing('Logement'),
  food('Alimentation'),
  transport('Transport'),
  restaurants('Restaurants'),
  leisure('Loisirs'),
  health('Santé'),
  shopping('Shopping'),
  subscriptions('Abonnements'),
  salary('Salaire'),
  savings('Épargne'),
  other('Divers');

  const TransactionCategory(this.label);

  /// Libellé affichable à l'utilisateur.
  final String label;
}

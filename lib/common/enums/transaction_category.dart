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

  /// Utilisée par les transferts entre comptes : ils ne sont ni un revenu ni
  /// une dépense, mais doivent tout de même être catégorisés.
  transfer('Transfert'),
  other('Divers');

  const TransactionCategory(this.label);

  /// Libellé affichable à l'utilisateur.
  final String label;
}

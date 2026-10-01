/// Catégories d'opérations financières « historiques ».
///
/// Les catégories sont désormais des données modifiables par l'utilisateur
/// (voir le module `features/categories`). Cette énumération ne sert plus qu'à
/// deux choses :
///
/// * fournir les **identifiants** des catégories par défaut créées au premier
///   lancement (`DefaultCategories`) — l'identifiant d'une catégorie est le nom
///   de la valeur (`TransactionCategory.food` → `food`) ;
/// * permettre la lecture des opérations enregistrées avant l'arrivée des
///   catégories personnalisables.
///
/// L'énumération ne dépend volontairement pas de Flutter : l'icône et la
/// couleur associées sont définies dans `CategoryVisuals`.
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
  transfer('Transfert'),
  other('Divers');

  const TransactionCategory(this.label);

  /// Libellé affiché à l'utilisateur.
  final String label;

  /// Identifiant utilisé pour les catégories par défaut.
  String get id => name;
}

class AppRoutes {
  // --- Onglets principaux (barre de navigation inférieure) ---

  /// Tableau de bord : écran affiché au démarrage de l'application.
  static const String dashboard = '/';
  static const String accounts = '/comptes';
  static const String operations = '/operations';
  static const String settings = '/parametres';

  // --- Comptes (sous-routes de l'onglet) ---

  /// Création d'un compte.
  static const String accountCreate = '$accounts/nouveau';

  /// Détail d'un compte.
  static String accountDetail(String id) => '$accounts/$id';

  /// Modification d'un compte.
  static String accountEdit(String id) => '$accounts/$id/modifier';

  // --- Opérations (sous-routes de l'onglet) ---

  /// Saisie rapide d'un revenu, d'une dépense ou d'un transfert.
  static const String operationCreate = '$operations/nouvelle';

  /// Modification d'une opération existante.
  static String operationEdit(String id) => '$operations/$id/modifier';

  // --- Paramètres (sous-routes de l'onglet) ---

  /// Gestion des catégories et de leurs sous-catégories.
  static const String categories = '$settings/categories';

  /// Budgets mensuels par catégorie.
  static const String budgets = '$settings/budgets';

  /// Nom et code PIN.
  static const String profile = '$settings/profil';

  /// Rappels de saisie (quotidien, hebdomadaire, mensuel).
  static const String reminders = '$settings/rappels';

  /// Devises suivies et taux de change mensuels.
  static const String currencies = '$settings/devises';

  /// Sauvegarde, export et import des données.
  static const String backup = '$settings/sauvegarde';

  // --- Patrimoine (sous-route du tableau de bord) ---

  /// Patrimoine et progression, ouvert depuis la carte « Patrimoine net » du
  /// tableau de bord.
  static const String wealth = '/progression';

  // --- Rapports (sous-route du tableau de bord) ---

  /// Rapports et analyses : dépenses par catégorie, par compte, comparaisons
  /// et export PDF / Excel.
  static const String reports = '/rapports';
}

class AppRoutes {
  // --- Onglets principaux (barre de navigation inférieure) ---

  /// Tableau de bord : écran affiché au démarrage de l'application.
  static const String dashboard = '/';
  static const String accounts = '/comptes';
  static const String operations = '/operations';
  static const String settings = '/parametres';

  // --- Authentification ---

  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

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

  // --- Patrimoine (sous-route du tableau de bord) ---

  /// Patrimoine et progression, ouvert depuis la carte « Patrimoine net » du
  /// tableau de bord.
  static const String wealth = '/progression';

  // --- Rapports (sous-route du tableau de bord) ---

  /// Rapports et analyses : dépenses par catégorie, par compte, comparaisons
  /// et export PDF / Excel.
  static const String reports = '/rapports';
}

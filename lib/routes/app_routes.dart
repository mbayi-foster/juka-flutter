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
}

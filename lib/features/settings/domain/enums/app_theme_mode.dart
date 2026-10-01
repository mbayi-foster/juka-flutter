/// Préférence d'affichage de l'application.
///
/// Le domaine reste indépendant de Flutter : la correspondance avec
/// `ThemeMode` est faite dans la couche de présentation.
enum AppThemeMode {
  system('Système', 'Suit le réglage du téléphone'),
  light('Clair', 'Toujours lumineux'),
  dark('Sombre', 'Toujours sombre');

  const AppThemeMode(this.label, this.description);

  /// Libellé affiché à l'utilisateur.
  final String label;

  /// Précision affichée sous le libellé.
  final String description;

  /// Valeur enregistrée en base.
  String get storageKey => name;

  /// Relit une préférence stockée ; retombe sur [AppThemeMode.system].
  static AppThemeMode fromStorage(String? value) {
    for (final mode in AppThemeMode.values) {
      if (mode.storageKey == value) return mode;
    }
    return AppThemeMode.system;
  }
}

/// Langues proposées par l'application.
///
/// Le domaine reste indépendant de Flutter : la correspondance avec `Locale`
/// est faite dans la couche de présentation.
enum AppLanguage {
  french('fr', 'Français'),
  english('en', 'English');

  const AppLanguage(this.code, this.label);

  /// Code ISO 639-1 (`fr`, `en`).
  final String code;

  /// Nom de la langue, affiché dans ses propres caractères.
  final String label;

  /// Valeur enregistrée en base.
  String get storageKey => code;

  /// Relit une préférence stockée ; retombe sur le français.
  static AppLanguage fromStorage(String? value) {
    for (final language in AppLanguage.values) {
      if (language.storageKey == value) return language;
    }
    return AppLanguage.french;
  }
}

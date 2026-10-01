import 'package:juka/features/settings/domain/enums/app_theme_mode.dart';

/// Contrat du domaine pour les préférences de l'application.
abstract interface class SettingsRepository {
  /// Préférence d'affichage enregistrée.
  Future<AppThemeMode> loadThemeMode();

  /// Enregistre la préférence d'affichage.
  Future<void> saveThemeMode(AppThemeMode mode);
}

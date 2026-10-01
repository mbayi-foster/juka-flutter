import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/features/settings/data/datasources/settings_sqflite_data_source.dart';
import 'package:juka/features/settings/domain/enums/app_theme_mode.dart';
import 'package:juka/features/settings/domain/repositories/settings_repository.dart';
import 'package:juka/shared/database/app_database.dart';

/// Préférences de l'application (stockage local).
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsSqfliteDataSource(ref.watch(appDatabaseProvider)),
);

/// Mode d'affichage choisi par l'utilisateur.
///
/// La préférence est lue après le premier rendu : l'application démarre sur le
/// réglage du système, puis bascule si l'utilisateur avait choisi un thème fixe.
final settingsControllerProvider =
    NotifierProvider<SettingsController, AppThemeMode>(SettingsController.new);

class SettingsController extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() {
    Future.microtask(_restore);
    return AppThemeMode.system;
  }

  Future<void> _restore() async {
    try {
      final mode = await ref.read(settingsRepositoryProvider).loadThemeMode();
      state = mode;
    } catch (_) {
      // Préférence illisible : on conserve le réglage du système.
      return;
    }
  }

  /// Applique immédiatement le thème, puis l'enregistre.
  ///
  /// Un échec d'enregistrement n'empêche pas le changement d'affichage.
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    try {
      await ref.read(settingsRepositoryProvider).saveThemeMode(mode);
    } catch (_) {
      return;
    }
  }
}

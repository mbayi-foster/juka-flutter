import 'package:sqflite/sqflite.dart';

import 'package:juka/features/settings/domain/enums/app_theme_mode.dart';
import 'package:juka/features/settings/domain/repositories/settings_repository.dart';
import 'package:juka/shared/database/app_database.dart';

/// Préférences de l'application, stockées en base (`app_settings`).
///
/// Le magasin est un simple couple clé/valeur : les préférences n'ont pas
/// besoin d'une couche de modèles, la source de données implémente donc
/// directement le contrat du domaine.
class SettingsSqfliteDataSource implements SettingsRepository {
  const SettingsSqfliteDataSource(this._appDatabase);

  static const String _table = 'app_settings';
  static const String _themeModeKey = 'theme_mode';

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  @override
  Future<AppThemeMode> loadThemeMode() async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'key = ?',
      whereArgs: [_themeModeKey],
      limit: 1,
    );

    if (rows.isEmpty) return AppThemeMode.system;
    return AppThemeMode.fromStorage(rows.first['value'] as String?);
  }

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async {
    final db = await _db;
    await db.insert(_table, {
      'key': _themeModeKey,
      'value': mode.storageKey,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

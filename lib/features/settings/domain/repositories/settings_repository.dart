import 'package:juka/features/settings/domain/entities/app_preferences.dart';
import 'package:juka/features/settings/domain/entities/local_profile.dart';
import 'package:juka/features/settings/domain/entities/settings_snapshot.dart';

/// Contrat du domaine pour les préférences et le profil local.
///
/// Tout est stocké sur le téléphone : aucun appel réseau n'est nécessaire.
abstract interface class SettingsRepository {
  /// Charge les préférences et le profil en une seule lecture.
  Future<SettingsSnapshot> load();

  /// Enregistre les préférences d'affichage et de rappels.
  Future<void> savePreferences(AppPreferences preferences);

  /// Enregistre le profil local (nom et code PIN).
  Future<void> saveProfile(LocalProfile profile);
}

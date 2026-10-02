import 'package:juka/features/settings/domain/entities/app_preferences.dart';
import 'package:juka/features/settings/domain/entities/local_profile.dart';

/// Tout ce qui est chargé au démarrage : préférences + profil local.
class SettingsSnapshot {
  const SettingsSnapshot({
    this.preferences = const AppPreferences(),
    this.profile = const LocalProfile(),
  });

  final AppPreferences preferences;
  final LocalProfile profile;
}

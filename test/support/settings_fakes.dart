import 'package:juka/features/settings/domain/entities/app_preferences.dart';
import 'package:juka/features/settings/domain/entities/local_profile.dart';
import 'package:juka/features/settings/domain/entities/settings_snapshot.dart';
import 'package:juka/features/settings/domain/repositories/settings_repository.dart';
import 'package:juka/features/settings/presentation/providers/settings_providers.dart';

/// Repository de test : préférences en mémoire, aucun accès à `sqflite`.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({
    this.snapshot = const SettingsSnapshot(profile: LocalProfile(name: 'Test')),
  });

  SettingsSnapshot snapshot;

  @override
  Future<SettingsSnapshot> load() async => snapshot;

  @override
  Future<void> savePreferences(AppPreferences preferences) async {
    snapshot = SettingsSnapshot(
      preferences: preferences,
      profile: snapshot.profile,
    );
  }

  @override
  Future<void> saveProfile(LocalProfile profile) async {
    snapshot = SettingsSnapshot(
      preferences: snapshot.preferences,
      profile: profile,
    );
  }
}

/// Surcharges à appliquer aux tests qui affichent l'application entière.
///
/// Le profil est déjà renseigné : la porte d'accès laisse donc passer, comme un
/// utilisateur qui a déjà fait sa première ouverture.
final settingsTestOverrides = [
  settingsRepositoryProvider.overrideWith((ref) => FakeSettingsRepository()),
];

import 'package:juka/features/settings/domain/entities/app_preferences.dart';
import 'package:juka/features/settings/domain/entities/local_profile.dart';

/// État global des réglages, chargé au démarrage de l'application.
///
/// Il porte à la fois les préférences d'affichage et le profil local : c'est lui
/// qui décide si l'application affiche l'accueil, l'écran de bienvenue (nom +
/// code PIN) ou l'écran de déverrouillage.
class SettingsState {
  const SettingsState({
    this.isReady = false,
    this.preferences = const AppPreferences(),
    this.profile = const LocalProfile(),
    this.isUnlocked = false,
  });

  /// `true` une fois les préférences lues : l'accueil peut s'afficher.
  final bool isReady;

  final AppPreferences preferences;
  final LocalProfile profile;

  /// `true` lorsque le code PIN a été saisi pour cette session.
  final bool isUnlocked;

  /// Première ouverture : le nom doit être renseigné.
  bool get needsOnboarding => !profile.isOnboarded;

  /// Le code PIN est actif et n'a pas encore été saisi.
  bool get isLocked => profile.hasPin && !isUnlocked;

  /// L'application peut afficher son contenu.
  bool get isAccessible => isReady && !needsOnboarding && !isLocked;

  SettingsState copyWith({
    bool? isReady,
    AppPreferences? preferences,
    LocalProfile? profile,
    bool? isUnlocked,
  }) {
    return SettingsState(
      isReady: isReady ?? this.isReady,
      preferences: preferences ?? this.preferences,
      profile: profile ?? this.profile,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}

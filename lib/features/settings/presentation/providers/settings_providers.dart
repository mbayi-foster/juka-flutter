import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/common/enums/app_date_format.dart';
import 'package:juka/common/enums/app_language.dart';
import 'package:juka/features/settings/data/datasources/settings_sqflite_data_source.dart';
import 'package:juka/features/settings/domain/entities/app_preferences.dart';
import 'package:juka/features/settings/domain/entities/local_profile.dart';
import 'package:juka/features/settings/domain/entities/reminder_settings.dart';
import 'package:juka/features/settings/domain/enums/app_theme_mode.dart';
import 'package:juka/features/settings/domain/repositories/settings_repository.dart';
import 'package:juka/features/settings/domain/services/pin_hasher.dart';
import 'package:juka/features/settings/presentation/state/settings_state.dart';
import 'package:juka/shared/database/app_settings_store.dart';
import 'package:juka/shared/utils/date_formatter.dart';

/// Réglages et profil local (stockage sur le téléphone).
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsSqfliteDataSource(ref.watch(appSettingsStoreProvider)),
);

/// État global des réglages : préférences, profil local et verrouillage.
final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);

class SettingsController extends Notifier<SettingsState> {
  /// Message affiché lorsque le code PIN saisi ne correspond pas.
  static const String pinErrorMessage = 'Code PIN incorrect.';

  /// Message affiché lorsque le code choisi n'a pas le bon format.
  static const String pinFormatMessage =
      'Choisissez un code de 4 à 6 chiffres.';

  @override
  SettingsState build() {
    Future.microtask(_restore);
    return const SettingsState();
  }

  /// Charge préférences et profil. Un échec de lecture (base indisponible) ne
  /// doit jamais bloquer l'application : on repart des valeurs par défaut.
  Future<void> _restore() async {
    try {
      final snapshot = await ref.read(settingsRepositoryProvider).load();
      DateFormatter.configure(
        language: snapshot.preferences.language,
        dateOrder: snapshot.preferences.dateFormat,
      );
      state = SettingsState(
        isReady: true,
        preferences: snapshot.preferences,
        profile: snapshot.profile,
      );
    } catch (_) {
      state = const SettingsState(isReady: true);
    }
  }

  // ---------------------------------------------------------------------
  // Préférences d'affichage
  // ---------------------------------------------------------------------

  Future<void> setThemeMode(AppThemeMode mode) =>
      _savePreferences(state.preferences.copyWith(themeMode: mode));

  Future<void> setLanguage(AppLanguage language) {
    DateFormatter.configure(language: language);
    return _savePreferences(state.preferences.copyWith(language: language));
  }

  Future<void> setDateFormat(AppDateFormat format) {
    DateFormatter.configure(dateOrder: format);
    return _savePreferences(state.preferences.copyWith(dateFormat: format));
  }

  Future<void> setReminders(ReminderSettings reminders) =>
      _savePreferences(state.preferences.copyWith(reminders: reminders));

  /// Définit la devise de référence (`null` pour revenir à l'affichage par
  /// devise).
  Future<void> setReferenceCurrency(AppCurrency? currency) => _savePreferences(
    state.preferences.copyWith(
      referenceCurrency: currency,
      clearReferenceCurrency: currency == null,
    ),
  );

  Future<void> _savePreferences(AppPreferences preferences) async {
    state = state.copyWith(preferences: preferences);
    try {
      await ref.read(settingsRepositoryProvider).savePreferences(preferences);
    } catch (_) {
      // Préférence appliquée en mémoire : l'échec d'écriture n'est pas bloquant.
      return;
    }
  }

  // ---------------------------------------------------------------------
  // Profil local (nom + code PIN)
  // ---------------------------------------------------------------------

  /// Termine la première ouverture. [pin] est facultatif : sans lui, le
  /// verrouillage reste désactivé.
  Future<void> completeOnboarding({required String name, String? pin}) async {
    var profile = LocalProfile(name: name.trim());
    if (pin != null && pin.isNotEmpty) profile = _withPin(profile, pin);

    // L'utilisateur vient de saisir son code : inutile de le redemander.
    await _saveProfile(profile, isUnlocked: true);
  }

  /// Change le nom affiché.
  Future<void> renameProfile(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _saveProfile(state.profile.copyWith(name: trimmed));
  }

  /// Active le verrouillage par code PIN.
  Future<String?> enablePin(String pin) async {
    if (!PinHasher.isValid(pin)) return pinFormatMessage;
    await _saveProfile(_withPin(state.profile, pin), isUnlocked: true);
    return null;
  }

  /// Désactive le verrouillage après vérification du code courant.
  Future<String?> disablePin({required String pin}) async {
    if (!_matchesPin(pin)) return pinErrorMessage;
    await _saveProfile(
      state.profile.copyWith(clearPin: true),
      isUnlocked: true,
    );
    return null;
  }

  /// Remplace le code PIN après vérification du code courant.
  Future<String?> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    if (!_matchesPin(currentPin)) return pinErrorMessage;
    if (!PinHasher.isValid(newPin)) return pinFormatMessage;
    await _saveProfile(_withPin(state.profile, newPin), isUnlocked: true);
    return null;
  }

  /// Vérifie un code PIN saisi à l'ouverture. Retourne `true` si l'accès est
  /// accordé.
  bool unlock(String pin) {
    if (!state.profile.hasPin) {
      state = state.copyWith(isUnlocked: true);
      return true;
    }
    if (!_matchesPin(pin)) return false;

    state = state.copyWith(isUnlocked: true);
    return true;
  }

  /// Verrouille immédiatement (mise en arrière-plan de l'application).
  void lock() => state = state.copyWith(isUnlocked: false);

  bool _matchesPin(String pin) {
    final salt = state.profile.pinSalt;
    final hash = state.profile.pinHash;
    if (salt == null || hash == null) return false;

    return PinHasher.matches(pin: pin, salt: salt, expectedHash: hash);
  }

  LocalProfile _withPin(LocalProfile profile, String pin) {
    final salt = PinHasher.generateSalt();
    return profile.copyWith(
      pinEnabled: true,
      pinHash: PinHasher.hash(pin, salt),
      pinSalt: salt,
    );
  }

  Future<void> _saveProfile(LocalProfile profile, {bool? isUnlocked}) async {
    state = state.copyWith(
      profile: profile,
      isUnlocked: isUnlocked ?? state.isUnlocked,
    );
    try {
      await ref.read(settingsRepositoryProvider).saveProfile(profile);
    } catch (_) {
      // Profil appliqué en mémoire : l'échec d'écriture n'est pas bloquant.
      return;
    }
  }
}

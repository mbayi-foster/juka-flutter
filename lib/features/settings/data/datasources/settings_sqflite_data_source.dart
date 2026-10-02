import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/common/enums/app_date_format.dart';
import 'package:juka/common/enums/app_language.dart';
import 'package:juka/features/settings/domain/entities/app_preferences.dart';
import 'package:juka/features/settings/domain/entities/local_profile.dart';
import 'package:juka/features/settings/domain/entities/reminder_settings.dart';
import 'package:juka/features/settings/domain/entities/settings_snapshot.dart';
import 'package:juka/features/settings/domain/enums/app_theme_mode.dart';
import 'package:juka/features/settings/domain/repositories/settings_repository.dart';
import 'package:juka/shared/database/app_settings_store.dart';

/// Implémentation locale de [SettingsRepository] sur la table `app_settings`.
///
/// Le magasin est un simple couple clé/valeur : les préférences n'ont pas
/// besoin d'un schéma dédié, la traduction clés ↔ objets est donc faite ici.
class SettingsSqfliteDataSource implements SettingsRepository {
  const SettingsSqfliteDataSource(this._store);

  static const String _themeModeKey = 'theme_mode';
  static const String _languageKey = 'language';
  static const String _dateFormatKey = 'date_format';
  static const String _referenceCurrencyKey = 'reference_currency';

  static const String _reminderDailyEnabledKey = 'reminder_daily_enabled';
  static const String _reminderDailyMinuteKey = 'reminder_daily_minute';
  static const String _reminderWeeklyEnabledKey = 'reminder_weekly_enabled';
  static const String _reminderWeeklyWeekdayKey = 'reminder_weekly_weekday';
  static const String _reminderWeeklyMinuteKey = 'reminder_weekly_minute';
  static const String _reminderMonthlyEnabledKey = 'reminder_monthly_enabled';
  static const String _reminderMonthlyDayKey = 'reminder_monthly_day';
  static const String _reminderMonthlyMinuteKey = 'reminder_monthly_minute';

  static const String _profileNameKey = 'profile_name';
  static const String _profilePinEnabledKey = 'profile_pin_enabled';
  static const String _profilePinHashKey = 'profile_pin_hash';
  static const String _profilePinSaltKey = 'profile_pin_salt';

  final AppSettingsStore _store;

  @override
  Future<SettingsSnapshot> load() async {
    final values = await _store.loadAll();
    return SettingsSnapshot(
      preferences: _preferencesFrom(values),
      profile: _profileFrom(values),
    );
  }

  @override
  Future<void> savePreferences(AppPreferences preferences) => _store.saveAll({
    _themeModeKey: preferences.themeMode.storageKey,
    _languageKey: preferences.language.storageKey,
    _dateFormatKey: preferences.dateFormat.storageKey,
    _referenceCurrencyKey: preferences.referenceCurrency?.code ?? '',
    _reminderDailyEnabledKey: _bool(preferences.reminders.dailyEnabled),
    _reminderDailyMinuteKey: '${preferences.reminders.dailyMinute}',
    _reminderWeeklyEnabledKey: _bool(preferences.reminders.weeklyEnabled),
    _reminderWeeklyWeekdayKey: '${preferences.reminders.weeklyWeekday}',
    _reminderWeeklyMinuteKey: '${preferences.reminders.weeklyMinute}',
    _reminderMonthlyEnabledKey: _bool(preferences.reminders.monthlyEnabled),
    _reminderMonthlyDayKey: '${preferences.reminders.monthlyDay}',
    _reminderMonthlyMinuteKey: '${preferences.reminders.monthlyMinute}',
  });

  @override
  Future<void> saveProfile(LocalProfile profile) => _store.saveAll({
    _profileNameKey: profile.name.trim(),
    _profilePinEnabledKey: _bool(profile.pinEnabled),
    _profilePinHashKey: profile.pinHash ?? '',
    _profilePinSaltKey: profile.pinSalt ?? '',
  });

  AppPreferences _preferencesFrom(Map<String, String> values) {
    return AppPreferences(
      themeMode: AppThemeMode.fromStorage(values[_themeModeKey]),
      language: AppLanguage.fromStorage(values[_languageKey]),
      dateFormat: AppDateFormat.fromStorage(values[_dateFormatKey]),
      referenceCurrency: _currencyFrom(values[_referenceCurrencyKey]),
      reminders: ReminderSettings(
        dailyEnabled: _readBool(values[_reminderDailyEnabledKey]),
        dailyMinute: _readInt(values[_reminderDailyMinuteKey], 20 * 60),
        weeklyEnabled: _readBool(values[_reminderWeeklyEnabledKey]),
        weeklyWeekday: _readInt(
          values[_reminderWeeklyWeekdayKey],
          DateTime.monday,
        ).clamp(DateTime.monday, DateTime.sunday),
        weeklyMinute: _readInt(values[_reminderWeeklyMinuteKey], 19 * 60),
        monthlyEnabled: _readBool(values[_reminderMonthlyEnabledKey]),
        monthlyDay: _readInt(values[_reminderMonthlyDayKey], 1).clamp(1, 28),
        monthlyMinute: _readInt(values[_reminderMonthlyMinuteKey], 9 * 60),
      ),
    );
  }

  LocalProfile _profileFrom(Map<String, String> values) {
    final hash = values[_profilePinHashKey];
    final salt = values[_profilePinSaltKey];

    return LocalProfile(
      name: values[_profileNameKey] ?? '',
      pinEnabled: _readBool(values[_profilePinEnabledKey]),
      pinHash: (hash == null || hash.isEmpty) ? null : hash,
      pinSalt: (salt == null || salt.isEmpty) ? null : salt,
    );
  }

  AppCurrency? _currencyFrom(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final currency in AppCurrency.values) {
      if (currency.code == code) return currency;
    }
    return null;
  }

  String _bool(bool value) => value ? '1' : '0';

  bool _readBool(String? value) => value == '1' || value == 'true';

  int _readInt(String? value, int fallback) =>
      value == null ? fallback : (int.tryParse(value) ?? fallback);
}

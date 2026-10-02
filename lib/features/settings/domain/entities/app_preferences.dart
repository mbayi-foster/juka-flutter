import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/common/enums/app_date_format.dart';
import 'package:juka/common/enums/app_language.dart';
import 'package:juka/features/settings/domain/entities/reminder_settings.dart';
import 'package:juka/features/settings/domain/enums/app_theme_mode.dart';

/// Préférences d'affichage et de confort de l'utilisateur.
///
/// Ces valeurs vivent uniquement sur le téléphone (`app_settings`) : aucune
/// n'est envoyée ailleurs.
class AppPreferences {
  const AppPreferences({
    this.themeMode = AppThemeMode.system,
    this.language = AppLanguage.french,
    this.dateFormat = AppDateFormat.dayFirst,
    this.reminders = const ReminderSettings(),
    this.referenceCurrency,
  });

  /// Thème clair / sombre / système.
  final AppThemeMode themeMode;

  /// Langue de l'interface.
  final AppLanguage language;

  /// Ordre d'écriture des dates numériques.
  final AppDateFormat dateFormat;

  /// Rappels de saisie quotidienne, hebdomadaire et mensuelle.
  final ReminderSettings reminders;

  /// Devise vers laquelle tous les montants sont ramenés pour être additionnés.
  ///
  /// `null` tant que l'utilisateur ne l'a pas choisie : l'application se
  /// contente alors d'afficher une devise à la fois.
  final AppCurrency? referenceCurrency;

  AppPreferences copyWith({
    AppThemeMode? themeMode,
    AppLanguage? language,
    AppDateFormat? dateFormat,
    ReminderSettings? reminders,
    AppCurrency? referenceCurrency,
    bool clearReferenceCurrency = false,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      dateFormat: dateFormat ?? this.dateFormat,
      reminders: reminders ?? this.reminders,
      referenceCurrency: clearReferenceCurrency
          ? null
          : (referenceCurrency ?? this.referenceCurrency),
    );
  }
}

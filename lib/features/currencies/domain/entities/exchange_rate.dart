import 'package:juka/common/enums/app_currency.dart';

/// Taux de change d'une devise pour un mois donné.
///
/// Le taux exprime combien vaut **une unité** de [currency] dans la devise de
/// référence choisie par l'utilisateur (ex. `1 USD = 2 850 CDF`). Il est saisi
/// mois par mois, car un taux change avec le temps.
class ExchangeRate {
  const ExchangeRate({
    required this.currency,
    required this.month,
    required this.rate,
  });

  /// Devise concernée (jamais la devise de référence : son taux vaut 1).
  final AppCurrency currency;

  /// Premier jour du mois concerné.
  final DateTime month;

  /// Valeur d'une unité de [currency] dans la devise de référence.
  final double rate;

  /// `true` lorsque [other] tombe dans le même mois calendaire.
  bool isSameMonth(DateTime other) =>
      month.year == other.year && month.month == other.month;

  /// Clé de stockage/regroupement : année × 12 + mois.
  static int monthKey(DateTime month) => month.year * 12 + month.month;

  ExchangeRate copyWith({double? rate}) =>
      ExchangeRate(currency: currency, month: month, rate: rate ?? this.rate);
}

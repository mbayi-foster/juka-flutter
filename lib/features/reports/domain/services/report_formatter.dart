import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/shared/utils/date_formatter.dart';
import 'package:juka/shared/utils/money_formatter.dart';

/// Mise en forme des valeurs d'un rapport pour les exports.
///
/// Le PDF et le CSV partagent ces conversions afin qu'un même chiffre ne
/// s'écrive jamais de deux façons différentes selon le format demandé.
abstract final class ReportFormatter {
  /// Valeur affichée lorsqu'une donnée n'existe pas (variation sans base de
  /// comparaison, par exemple).
  ///
  /// Un simple tiret : les polices standard du PDF (Helvetica) ne savent pas
  /// dessiner le tiret cadratin, qui s'afficherait alors en caractère manquant.
  static const String emptyValue = '-';

  /// `2 145,00` — montant **sans symbole** : un tableur doit pouvoir
  /// l'additionner.
  static String amount(AppCurrency currency, double value) =>
      MoneyFormatter.number(value, decimals: currency.decimalDigits);

  /// `39,6 %` — part d'un total.
  static String share(double ratio) =>
      MoneyFormatter.percent(ratio, withSign: false);

  /// `+12,3 %` — variation, [emptyValue] si la base manque.
  static String change(double? ratio) =>
      ratio == null ? emptyValue : MoneyFormatter.percent(ratio);

  /// `05/09/2026`.
  static String date(DateTime date) => DateFormatter.numeric(date);

  /// `sept. 2026`.
  static String month(DateTime date) => DateFormatter.shortMonthYear(date);
}

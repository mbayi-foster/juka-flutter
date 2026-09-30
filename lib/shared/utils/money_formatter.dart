import 'package:juka/common/enums/app_currency.dart';

/// Formatage des nombres, montants et pourcentages au format français.
///
/// Implémenté sans dépendance externe (pas d'`intl`) pour garder le projet
/// léger : séparateur de milliers = espace, séparateur décimal = virgule.
abstract final class MoneyFormatter {
  /// `1234.5` → `1 234,50 €`, ou `1234500` → `1 234 500 F CFA` en [AppCurrency.xof].
  ///
  /// Le symbole et le nombre de décimales proviennent de [currency] ;
  /// [decimals] permet de les forcer ponctuellement.
  /// [withSign] ajoute un `+` devant les montants positifs (les négatifs sont
  /// toujours préfixés d'un `-`).
  static String currency(
    double value, {
    AppCurrency currency = AppCurrency.eur,
    int? decimals,
    bool withSign = false,
  }) {
    final sign = withSign && value > 0 ? '+' : '';
    final digits = decimals ?? currency.decimalDigits;
    return '$sign${number(value, decimals: digits)} ${currency.symbol}';
  }

  /// Analyse une saisie utilisateur (`1 234,50` → `1234.5`).
  ///
  /// Accepte les espaces (y compris insécables) et la virgule décimale.
  static double? tryParse(String input) {
    final cleaned = input
        .trim()
        .replaceAll(' ', '')
        .replaceAll('\u00A0', '')
        .replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// `1234.5` → `1 234,50`.
  static String number(double value, {int decimals = 2}) {
    final isNegative = value < 0;
    final parts = value.abs().toStringAsFixed(decimals).split('.');
    final grouped = _groupThousands(parts.first);
    final result = parts.length > 1 && decimals > 0
        ? '$grouped,${parts[1]}'
        : grouped;
    return isNegative ? '-$result' : result;
  }

  /// `0.032` → `+3,2 %`.
  static String percent(
    double ratio, {
    int decimals = 1,
    bool withSign = true,
  }) {
    final value = ratio * 100;
    final sign = withSign && value > 0 ? '+' : '';
    return '$sign${number(value, decimals: decimals)} %';
  }

  static String _groupThousands(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

/// Raccourci de formatage : `account.currency.format(1234.5)`.
extension AppCurrencyFormatting on AppCurrency {
  String format(double value, {bool withSign = false}) =>
      MoneyFormatter.currency(value, currency: this, withSign: withSign);
}

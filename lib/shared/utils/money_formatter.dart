/// Formatage des nombres, montants et pourcentages au format français.
///
/// Implémenté sans dépendance externe (pas d'`intl`) pour garder le projet
/// léger : séparateur de milliers = espace, séparateur décimal = virgule.
abstract final class MoneyFormatter {
  static const String _currencySymbol = '€';

  /// `1234.5` → `1 234,50 €`.
  ///
  /// [withSign] ajoute un `+` devant les montants positifs (les négatifs sont
  /// toujours préfixés d'un `-`).
  static String currency(
    double value, {
    int decimals = 2,
    bool withSign = false,
  }) {
    final sign = withSign && value > 0 ? '+' : '';
    return '$sign${number(value, decimals: decimals)} $_currencySymbol';
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

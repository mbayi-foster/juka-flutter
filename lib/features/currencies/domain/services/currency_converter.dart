import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/currencies/domain/entities/exchange_rate.dart';

/// Convertit des montants vers la devise de référence.
///
/// Toutes les méthodes sont pures : l'objet est construit à partir des taux
/// stockés, ce qui rend la conversion testable sans base de données.
class CurrencyConverter {
  const CurrencyConverter({required this.reference, this.rates = const {}});

  /// Devise dans laquelle tous les montants sont ramenés.
  final AppCurrency reference;

  /// Devise → (année × 12 + mois) → taux vers [reference].
  final Map<AppCurrency, Map<int, double>> rates;

  /// Construit la table des taux à partir des lignes stockées.
  static Map<AppCurrency, Map<int, double>> groupRates(
    List<ExchangeRate> rates,
  ) {
    final grouped = <AppCurrency, Map<int, double>>{};
    for (final rate in rates) {
      grouped.putIfAbsent(
        rate.currency,
        () => {},
      )[ExchangeRate.monthKey(rate.month)] = rate.rate;
    }
    return grouped;
  }

  /// `true` lorsque la devise peut être convertie (ou qu'il s'agit de la
  /// référence).
  bool supports(AppCurrency currency) =>
      currency == reference || (rates[currency]?.isNotEmpty ?? false);

  /// Taux applicable à [currency] pour [month].
  ///
  /// Le taux du mois est utilisé en priorité ; à défaut, le taux connu le plus
  /// récent qui le précède, puis, pour un mois antérieur à tout taux saisi, le
  /// plus ancien connu. `null` lorsqu'aucun taux n'existe.
  double? rateOf(AppCurrency currency, DateTime month) {
    if (currency == reference) return 1;

    final byMonth = rates[currency];
    if (byMonth == null || byMonth.isEmpty) return null;

    final key = ExchangeRate.monthKey(month);
    final exact = byMonth[key];
    if (exact != null) return exact;

    final keys = byMonth.keys.toList()..sort();
    double? previous;
    for (final candidate in keys) {
      if (candidate > key) break;
      previous = byMonth[candidate];
    }
    return previous ?? byMonth[keys.first];
  }

  /// Montant converti en [reference], `null` si aucun taux n'est disponible.
  double? convert(double amount, AppCurrency from, DateTime month) {
    final rate = rateOf(from, month);
    return rate == null ? null : amount * rate;
  }
}

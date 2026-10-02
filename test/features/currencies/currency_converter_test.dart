import 'package:flutter_test/flutter_test.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/currencies/domain/entities/exchange_rate.dart';
import 'package:juka/features/currencies/domain/services/currency_converter.dart';

ExchangeRate _rate(AppCurrency currency, DateTime month, double rate) =>
    ExchangeRate(currency: currency, month: month, rate: rate);

void main() {
  group('CurrencyConverter', () {
    test('la devise de référence vaut toujours 1', () {
      const converter = CurrencyConverter(reference: AppCurrency.cdf);

      expect(converter.rateOf(AppCurrency.cdf, DateTime(2026, 9)), 1);
      expect(converter.convert(1500, AppCurrency.cdf, DateTime(2026, 9)), 1500);
    });

    test('utilise le taux du mois, sinon le plus récent précédent', () {
      final converter = CurrencyConverter(
        reference: AppCurrency.cdf,
        rates: {
          AppCurrency.usd: {
            ExchangeRate.monthKey(DateTime(2026, 7)): 2700,
            ExchangeRate.monthKey(DateTime(2026, 9)): 2850,
          },
        },
      );

      // Mois exact.
      expect(converter.rateOf(AppCurrency.usd, DateTime(2026, 9)), 2850);
      // Mois sans taux : on reprend celui de juillet.
      expect(converter.rateOf(AppCurrency.usd, DateTime(2026, 8)), 2700);
      // Mois postérieur au dernier taux connu.
      expect(converter.rateOf(AppCurrency.usd, DateTime(2026, 12)), 2850);
      // Mois antérieur à tout taux : le plus ancien connu.
      expect(converter.rateOf(AppCurrency.usd, DateTime(2026, 1)), 2700);
    });

    test('convertit un montant au taux du mois de l\'opération', () {
      final converter = CurrencyConverter(
        reference: AppCurrency.cdf,
        rates: {
          AppCurrency.usd: {
            ExchangeRate.monthKey(DateTime(2026, 9)): 2850,
          },
        },
      );

      expect(converter.convert(10, AppCurrency.usd, DateTime(2026, 9, 12)), 28500);
    });

    test('sans taux, la devise n\'est pas convertible', () {
      const converter = CurrencyConverter(reference: AppCurrency.cdf);

      expect(converter.supports(AppCurrency.usd), isFalse);
      expect(converter.rateOf(AppCurrency.usd, DateTime(2026, 9)), isNull);
      expect(converter.convert(10, AppCurrency.usd, DateTime(2026, 9)), isNull);
      expect(converter.supports(AppCurrency.cdf), isTrue);
    });

    test('regroupe les taux par devise et par mois', () {
      final grouped = CurrencyConverter.groupRates([
        _rate(AppCurrency.usd, DateTime(2026, 9), 2850),
        _rate(AppCurrency.usd, DateTime(2026, 8), 2700),
        _rate(AppCurrency.eur, DateTime(2026, 9), 3100),
      ]);

      expect(grouped[AppCurrency.usd], {
        ExchangeRate.monthKey(DateTime(2026, 8)): 2700,
        ExchangeRate.monthKey(DateTime(2026, 9)): 2850,
      });
      expect(grouped[AppCurrency.eur]!.length, 1);
    });
  });
}

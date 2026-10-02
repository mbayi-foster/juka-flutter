import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/currencies/data/datasources/currencies_sqflite_data_source.dart';
import 'package:juka/features/currencies/domain/entities/exchange_rate.dart';
import 'package:juka/features/currencies/domain/repositories/currencies_repository.dart';
import 'package:juka/features/currencies/domain/services/currency_converter.dart';
import 'package:juka/features/settings/presentation/providers/settings_providers.dart';
import 'package:juka/shared/database/app_database.dart';

/// Devises suivies et taux de change (stockage local).
final currenciesRepositoryProvider = Provider<CurrenciesRepository>(
  (ref) => CurrenciesSqfliteDataSource(ref.watch(appDatabaseProvider)),
);

/// Devises suivies par l'utilisateur, pour l'écran de réglages.
final trackedCurrenciesProvider = FutureProvider<List<AppCurrency>>(
  (ref) => ref.watch(currenciesRepositoryProvider).fetchTrackedCurrencies(),
);

/// Taux de change en mémoire.
class ExchangeRatesState {
  const ExchangeRatesState({this.isReady = false, this.rates = const {}});

  /// `true` une fois les taux lus.
  final bool isReady;

  /// Devise → (année × 12 + mois) → taux vers la devise de référence.
  final Map<AppCurrency, Map<int, double>> rates;

  /// Taux enregistré pour une devise et un mois, `null` si absent.
  double? rateFor(AppCurrency currency, DateTime month) =>
      rates[currency]?[ExchangeRate.monthKey(month)];
}

/// Charge les taux au démarrage (table minuscule) : le convertisseur reste
/// ainsi synchrone, ce dont ont besoin les repositories du tableau de bord et
/// des rapports.
final exchangeRatesControllerProvider =
    NotifierProvider<ExchangeRatesController, ExchangeRatesState>(
      ExchangeRatesController.new,
    );

class ExchangeRatesController extends Notifier<ExchangeRatesState> {
  @override
  ExchangeRatesState build() {
    Future.microtask(reload);
    return const ExchangeRatesState();
  }

  /// Relit tous les taux enregistrés.
  Future<void> reload() async {
    try {
      final rates = await ref.read(currenciesRepositoryProvider).fetchRates();
      state = ExchangeRatesState(
        isReady: true,
        rates: CurrencyConverter.groupRates(rates),
      );
    } catch (_) {
      state = const ExchangeRatesState(isReady: true);
    }
  }

  /// Ajoute une devise à suivre.
  Future<void> track(AppCurrency currency) async {
    try {
      await ref.read(currenciesRepositoryProvider).trackCurrency(currency);
    } catch (_) {
      return;
    }
    ref.invalidate(trackedCurrenciesProvider);
  }

  /// Retire une devise et ses taux.
  Future<void> untrack(AppCurrency currency) async {
    try {
      await ref.read(currenciesRepositoryProvider).untrackCurrency(currency);
    } catch (_) {
      return;
    }
    ref.invalidate(trackedCurrenciesProvider);
    await reload();
  }

  /// Enregistre le taux d'une devise pour un mois.
  Future<void> saveRate({
    required AppCurrency currency,
    required DateTime month,
    required double rate,
  }) async {
    try {
      await ref
          .read(currenciesRepositoryProvider)
          .saveRate(currency: currency, month: month, rate: rate);
    } catch (_) {
      return;
    }
    await reload();
  }

  /// Supprime le taux d'une devise pour un mois.
  Future<void> deleteRate({
    required AppCurrency currency,
    required DateTime month,
  }) async {
    try {
      await ref
          .read(currenciesRepositoryProvider)
          .deleteRate(currency: currency, month: month);
    } catch (_) {
      return;
    }
    await reload();
  }
}

/// Convertisseur vers la devise de référence, `null` tant que l'utilisateur
/// n'en a pas choisi : le tableau de bord garde alors son affichage par devise.
final currencyConverterProvider = Provider<CurrencyConverter?>((ref) {
  final reference = ref.watch(
    settingsControllerProvider.select(
      (state) => state.preferences.referenceCurrency,
    ),
  );
  if (reference == null) return null;

  final rates = ref.watch(exchangeRatesControllerProvider).rates;
  return CurrencyConverter(reference: reference, rates: rates);
});

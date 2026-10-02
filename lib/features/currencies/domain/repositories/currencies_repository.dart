import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/currencies/domain/entities/exchange_rate.dart';

/// Contrat du domaine pour les devises suivies et les taux de change.
///
/// Les taux sont saisis **mois par mois** par l'utilisateur et restent sur le
/// téléphone : l'application ne récupère aucun taux en ligne.
abstract interface class CurrenciesRepository {
  /// Devises que l'utilisateur suit, dans l'ordre où il les a ajoutées.
  Future<List<AppCurrency>> fetchTrackedCurrencies();

  /// Ajoute une devise à suivre.
  Future<void> trackCurrency(AppCurrency currency);

  /// Retire une devise suivie (et ses taux).
  Future<void> untrackCurrency(AppCurrency currency);

  /// Tous les taux enregistrés, toutes devises et tous mois confondus.
  Future<List<ExchangeRate>> fetchRates();

  /// Enregistre le taux d'une devise pour un mois.
  Future<void> saveRate({
    required AppCurrency currency,
    required DateTime month,
    required double rate,
  });

  /// Supprime le taux d'une devise pour un mois.
  Future<void> deleteRate({
    required AppCurrency currency,
    required DateTime month,
  });

  /// Efface toutes les devises suivies et leurs taux.
  Future<void> clear();
}

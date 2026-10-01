import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/wealth/domain/entities/net_worth_snapshot.dart';

/// Contrat du domaine pour l'historique du patrimoine.
///
/// L'implémentation concrète vit dans la couche `data` : le domaine ignore si
/// les photos sont stockées en base locale ou côté serveur.
abstract interface class WealthRepository {
  /// Photos enregistrées pour [currency], de la plus ancienne à la plus
  /// récente.
  Future<List<NetWorthSnapshot>> fetchSnapshots({
    required AppCurrency currency,
    int? limit,
  });

  /// Enregistre la photo d'un mois (remplace celle du même mois si elle
  /// existe déjà).
  Future<NetWorthSnapshot> saveSnapshot(NetWorthSnapshot snapshot);

  /// Supprime toutes les photos d'une devise (utilisé par les tests).
  Future<void> clearSnapshots(AppCurrency currency);
}

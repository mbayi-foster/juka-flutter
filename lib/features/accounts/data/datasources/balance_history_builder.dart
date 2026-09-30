import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/accounts/domain/entities/account_balance_point.dart';

/// Construit l'historique de solde d'un compte.
///
/// Tant que les opérations ne sont pas persistées, l'historique est déduit du
/// solde courant selon une progression régulière. Ce calcul est partagé par
/// toutes les implémentations de `AccountsLocalDataSource` (mémoire, SQLite)
/// afin qu'elles se comportent de la même façon.
abstract final class BalanceHistoryBuilder {
  /// Nombre de mois d'historique exposés.
  static const int months = 6;

  /// Progression appliquée au solde courant, du mois le plus ancien au mois
  /// courant (le dernier facteur vaut 1 : on retombe sur le solde actuel).
  static const List<double> _progression = [0.72, 0.79, 0.85, 0.91, 0.96, 1];

  static List<AccountBalancePoint> build(Account account, {DateTime? now}) {
    final reference = now ?? DateTime.now();

    return [
      for (var monthsAgo = months - 1; monthsAgo >= 0; monthsAgo--)
        AccountBalancePoint(
          month: DateTime(reference.year, reference.month - monthsAgo),
          balance:
              account.currentBalance * _progression[months - 1 - monthsAgo],
        ),
    ];
  }
}

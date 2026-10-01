import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:juka/features/operations/domain/entities/operation_filter.dart';
import 'package:juka/features/operations/domain/repositories/operations_repository.dart';
import 'package:juka/features/wealth/domain/entities/net_worth_snapshot.dart';
import 'package:juka/features/wealth/domain/entities/wealth_overview.dart';
import 'package:juka/features/wealth/domain/repositories/wealth_repository.dart';
import 'package:juka/features/wealth/domain/services/wealth_calculator.dart';

/// Enregistre la « photo » du patrimoine pour un mois.
///
/// C'est ce cas d'usage qui rend le suivi automatique : appelé à l'ouverture de
/// l'application, il fige le patrimoine du mois en cours (et le met à jour tant
/// que le mois n'est pas terminé).
class RefreshNetWorthSnapshotUseCase {
  const RefreshNetWorthSnapshotUseCase(
    this._wealthRepository,
    this._accountsRepository,
  );

  final WealthRepository _wealthRepository;
  final AccountsRepository _accountsRepository;

  /// Calcule la photo à partir des comptes actuels puis l'enregistre.
  ///
  /// Retourne `null` si aucun compte n'existe (ou si [currency] n'en a aucun).
  Future<NetWorthSnapshot?> call({
    AppCurrency? currency,
    DateTime? month,
  }) async {
    final accounts = await _accountsRepository.fetchAccounts();
    final target = currency ?? WealthCalculator.primaryCurrency(accounts);
    if (target == null) return null;
    if (WealthCalculator.accountsOf(accounts, target).isEmpty) return null;

    final snapshot = WealthCalculator.snapshot(
      accounts: accounts,
      currency: target,
      month: month ?? DateTime.now(),
    );
    return _wealthRepository.saveSnapshot(snapshot);
  }
}

/// Construit l'écran « Patrimoine et progression » pour une devise.
class GetWealthOverviewUseCase {
  const GetWealthOverviewUseCase(
    this._wealthRepository,
    this._accountsRepository,
    this._operationsRepository,
  );

  final WealthRepository _wealthRepository;
  final AccountsRepository _accountsRepository;
  final OperationsRepository _operationsRepository;

  /// Fenêtre d'observation utilisée pour estimer le remboursement mensuel.
  static const int paymentWindowDays = 90;

  /// Retourne `null` si aucun compte n'existe pour la devise demandée.
  Future<WealthOverview?> call({AppCurrency? currency, DateTime? now}) async {
    final reference = now ?? DateTime.now();
    final accounts = await _accountsRepository.fetchAccounts();
    final target = currency ?? WealthCalculator.primaryCurrency(accounts);
    if (target == null) return null;

    final currencyAccounts = WealthCalculator.accountsOf(accounts, target);
    if (currencyAccounts.isEmpty) return null;

    // Photo automatique du mois : recalculée à chaque ouverture puis figée.
    final current = await _wealthRepository.saveSnapshot(
      WealthCalculator.snapshot(
        accounts: accounts,
        currency: target,
        month: reference,
      ),
    );

    final history = await _wealthRepository.fetchSnapshots(
      currency: target,
      limit: WealthCalculator.historyMonths,
    );

    final (income, expenses) = await _monthlyFlow(reference);
    final payments = await _averageMonthlyPayments(currencyAccounts, reference);

    return WealthOverview(
      currency: target,
      current: current,
      previousMonth: _previousMonth(history, reference),
      history: history,
      indicators: WealthCalculator.indicators(
        accounts: accounts,
        currency: target,
        monthlyIncome: income,
        monthlyExpenses: expenses,
        now: reference,
      ),
      debts: WealthCalculator.debts(
        accounts: accounts,
        currency: target,
        monthlyPayments: payments,
      ),
      accounts: currencyAccounts,
    );
  }

  /// Revenus et dépenses du mois en cours (transferts exclus).
  Future<(double, double)> _monthlyFlow(DateTime reference) async {
    final operations = await _operationsRepository.fetchOperations(
      OperationFilter(
        from: DateTime(reference.year, reference.month),
        to: DateTime(reference.year, reference.month + 1, 0, 23, 59, 59),
      ),
    );

    var income = 0.0;
    var expenses = 0.0;
    for (final operation in operations) {
      if (!operation.type.countsInStats) continue;
      if (operation.isIncome) {
        income += operation.amount;
      } else {
        expenses += operation.amount;
      }
    }
    return (income, expenses);
  }

  /// Rythme de remboursement mensuel moyen par compte de dette.
  ///
  /// Sont considérés comme des remboursements les montants qui arrivent sur le
  /// compte de dette (transfert entrant ou revenu).
  Future<Map<String, double>> _averageMonthlyPayments(
    List<Account> accounts,
    DateTime reference,
  ) async {
    final hasLiability = accounts.any((account) => account.type.isLiability);
    if (!hasLiability) return const {};

    final from = DateTime(
      reference.year,
      reference.month,
      reference.day,
    ).subtract(const Duration(days: paymentWindowDays));

    final operations = await _operationsRepository.fetchOperations(
      OperationFilter(from: from, to: reference),
    );

    final totals = <String, double>{};
    for (final operation in operations) {
      final transferTarget = operation.transferAccountId;
      if (operation.type.isTransfer && transferTarget != null) {
        totals.update(
          transferTarget,
          (total) => total + operation.amount,
          ifAbsent: () => operation.amount,
        );
      } else if (operation.isIncome) {
        totals.update(
          operation.accountId,
          (total) => total + operation.amount,
          ifAbsent: () => operation.amount,
        );
      }
    }

    final months = paymentWindowDays / 30;
    return {
      for (final entry in totals.entries) entry.key: entry.value / months,
    };
  }

  /// Photo du mois précédent, `null` si elle n'a jamais été enregistrée.
  NetWorthSnapshot? _previousMonth(
    List<NetWorthSnapshot> history,
    DateTime reference,
  ) {
    final target = DateTime(reference.year, reference.month - 1);
    for (final snapshot in history) {
      if (snapshot.isSameMonth(target)) return snapshot;
    }
    return null;
  }
}

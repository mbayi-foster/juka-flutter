import 'package:juka/common/enums/account_type.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/wealth/domain/entities/debt_progress.dart';
import 'package:juka/features/wealth/domain/entities/net_worth_snapshot.dart';
import 'package:juka/features/wealth/domain/entities/wealth_indicators.dart';

/// Calculs du patrimoine, à partir des comptes et des opérations.
///
/// Toutes les méthodes sont pures : elles ne dépendent ni de la base ni de
/// l'interface, ce qui permet de les réutiliser (tableau de bord, écran
/// Patrimoine) et de les tester isolément.
abstract final class WealthCalculator {
  /// Nombre de mois d'historique affichés sur la courbe.
  static const int historyMonths = 12;

  /// Comptes actifs (non archivés) d'une devise.
  static List<Account> accountsOf(
    List<Account> accounts,
    AppCurrency currency,
  ) => accounts
      .where((account) => !account.isArchived && account.currency == currency)
      .toList();

  /// Devise principale : celle qui concentre le plus de montants.
  ///
  /// Les devises n'étant pas converties, c'est celle-ci que l'écran Patrimoine
  /// affiche en premier.
  static AppCurrency? primaryCurrency(List<Account> accounts) {
    final weights = <AppCurrency, double>{};

    for (final account in accounts) {
      if (account.isArchived) continue;
      final weight = account.currentBalance.abs();
      weights.update(
        account.currency,
        (total) => total + weight,
        ifAbsent: () => weight,
      );
    }

    if (weights.isEmpty) return null;
    final sorted = weights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  /// Photo du patrimoine d'une devise à un mois donné.
  ///
  /// Un compte d'actif à découvert bascule du côté des dettes.
  static NetWorthSnapshot snapshot({
    required List<Account> accounts,
    required AppCurrency currency,
    required DateTime month,
    DateTime? recordedAt,
  }) {
    var assets = 0.0;
    var liabilities = 0.0;

    for (final account in accountsOf(accounts, currency)) {
      final balance = account.currentBalance;

      if (account.type.isLiability) {
        liabilities += balance.abs();
      } else if (balance >= 0) {
        assets += balance;
      } else {
        liabilities += balance.abs();
      }
    }

    return NetWorthSnapshot(
      month: DateTime(month.year, month.month),
      currency: currency,
      assets: assets,
      liabilities: liabilities,
      recordedAt: recordedAt ?? DateTime.now(),
    );
  }

  /// Actifs mobilisables rapidement : hors dettes et hors créances.
  static double liquidAssets(List<Account> accounts, AppCurrency currency) {
    var total = 0.0;

    for (final account in accountsOf(accounts, currency)) {
      if (account.type.isLiability || account.type.isReceivable) continue;
      if (account.currentBalance > 0) total += account.currentBalance;
    }

    return total;
  }

  /// Indicateurs de progression pour une devise.
  static WealthIndicators indicators({
    required List<Account> accounts,
    required AppCurrency currency,
    required double monthlyIncome,
    required double monthlyExpenses,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final current = snapshot(
      accounts: accounts,
      currency: currency,
      month: reference,
    );
    final liquid = liquidAssets(accounts, currency);

    return WealthIndicators(
      savingsRate: monthlyIncome <= 0
          ? null
          : (monthlyIncome - monthlyExpenses) / monthlyIncome,
      emergencyFundMonths: monthlyExpenses <= 0
          ? null
          : liquid / monthlyExpenses,
      debtRatio: current.assets <= 0
          ? null
          : current.liabilities / current.assets,
      monthlyExpenses: monthlyExpenses,
      liquidAssets: liquid,
    );
  }

  /// Dettes d'une devise, de la plus lourde à la plus légère.
  static List<DebtProgress> debts({
    required List<Account> accounts,
    required AppCurrency currency,
    Map<String, double> monthlyPayments = const {},
  }) {
    final liabilities =
        accountsOf(
          accounts,
          currency,
        ).where((account) => account.type.isLiability).toList()..sort(
          (a, b) => b.currentBalance.abs().compareTo(a.currentBalance.abs()),
        );

    return [
      for (final account in liabilities)
        DebtProgress(
          account: account,
          initialDebt: account.initialBalance.abs(),
          remainingDebt: account.currentBalance.abs(),
          averageMonthlyPayment: monthlyPayments[account.id] ?? 0,
        ),
    ];
  }

  /// Comptes d'actifs (hors dettes) triés du plus gros au plus petit.
  static List<Account> assetAccounts(
    List<Account> accounts,
    AppCurrency currency,
  ) {
    final assets =
        accountsOf(accounts, currency)
            .where(
              (account) =>
                  !account.type.isLiability && account.currentBalance > 0,
            )
            .toList()
          ..sort((a, b) => b.currentBalance.compareTo(a.currentBalance));
    return assets;
  }

  /// Types de comptes considérés comme des dettes.
  static bool isLiabilityType(AccountType type) => type.isLiability;
}

import 'package:juka/common/enums/account_type.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/common/enums/transaction_category.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/categories/domain/entities/category.dart';
import 'package:juka/features/operations/domain/entities/operation.dart';
import 'package:juka/features/reports/domain/entities/account_breakdown.dart';
import 'package:juka/features/reports/domain/entities/category_breakdown.dart';
import 'package:juka/features/reports/domain/entities/expense_report.dart';
import 'package:juka/features/reports/domain/entities/monthly_comparison.dart';
import 'package:juka/features/reports/domain/entities/report_period.dart';
import 'package:juka/features/reports/domain/entities/report_totals.dart';
import 'package:juka/features/reports/domain/entities/top_expense.dart';
import 'package:juka/features/reports/domain/entities/trend_analysis.dart';
import 'package:juka/features/reports/domain/enums/trend_direction.dart';

/// Calcule le rapport « Rapports et analyses » à partir des données brutes.
///
/// Toutes les méthodes sont pures : l'écran, le PDF et le CSV partagent donc
/// exactement les mêmes chiffres, et le calcul est testable sans base de
/// données.
abstract final class ReportsCalculator {
  /// Nombre de dépenses listées dans le « top ».
  static const int topExpenseCount = 5;

  /// Nombre de catégories retenues dans les tendances.
  static const int maxMovers = 4;

  /// Nombre de mois affichés sur la tendance.
  static const int trendMonths = 6;

  /// Nombre de mois utilisés pour les moyennes comparées.
  static const int averageMonths = 3;

  /// En deçà de ce seuil, une variation est considérée comme stable.
  static const double stableThreshold = 0.05;

  /// Couleur de repli (`AppColors.categoryOther`) pour une catégorie supprimée.
  static const int fallbackColor = 0xFF8A8A8A;

  /// Clé d'icône de repli (`CategoryVisuals.defaultIconKey`).
  static const String fallbackIconKey = 'other';

  /// Première opération à charger pour couvrir la période, son comparatif **et**
  /// la fenêtre de tendance.
  ///
  /// C'est cette date qu'il faut passer au filtre du repository : une seule
  /// requête suffit ensuite pour tous les calculs.
  static DateTime windowStart(ReportPeriod period) {
    final trendStart = DateTime(
      period.end.year,
      period.end.month - (trendMonths - 1),
    );
    final comparisonStart = period.previous.start;
    return comparisonStart.isBefore(trendStart) ? comparisonStart : trendStart;
  }

  /// Devise à analyser.
  ///
  /// [requested] est le choix explicite de l'utilisateur : il est respecté
  /// tant que des comptes actifs l'utilisent. Sans choix, la devise retenue est
  /// celle qui porte le plus d'opérations sur la période. Une devise sans
  /// activité — par exemple un compte d'épargne libellé dans une autre devise —
  /// ne peut donc jamais masquer les chiffres réels. [fallback] prend le relais
  /// lorsque la période ne contient aucune opération.
  static AppCurrency resolveCurrency({
    required List<Operation> operations,
    required List<Account> accounts,
    required ReportPeriod period,
    required AppCurrency fallback,
    AppCurrency? requested,
  }) {
    final available = {
      for (final account in accounts)
        if (!account.isArchived) account.currency,
    };

    if (requested != null && available.contains(requested)) return requested;

    final currencyByAccount = {
      for (final account in accounts) account.id: account.currency,
    };
    final counts = <AppCurrency, int>{};

    for (final operation in operations) {
      if (!operation.type.countsInStats || !period.contains(operation.date)) {
        continue;
      }
      final currency = currencyByAccount[operation.accountId];
      if (currency == null || !available.contains(currency)) continue;
      counts.update(currency, (count) => count + 1, ifAbsent: () => 1);
    }

    AppCurrency? mostActive;
    var bestCount = 0;
    for (final entry in counts.entries) {
      if (entry.value <= bestCount) continue;
      mostActive = entry.key;
      bestCount = entry.value;
    }

    return mostActive ?? fallback;
  }

  /// Construit le rapport complet.
  ///
  /// [operations] doit couvrir au moins [windowStart] jusqu'à la fin de
  /// [period] : le comparatif et la tendance en sont déduits. Seules les
  /// opérations de [currency] sont retenues, et [accountId] restreint
  /// éventuellement le périmètre à un compte.
  static ExpenseReport build({
    required ReportPeriod period,
    required List<Operation> operations,
    required List<Category> categories,
    required List<Account> accounts,
    required AppCurrency currency,
    String? accountId,
  }) {
    final accountsById = {for (final account in accounts) account.id: account};
    final categoriesById = {
      for (final category in categories) category.id: category,
    };
    final scope = {
      for (final account in accounts)
        if (account.currency == currency &&
            (accountId == null || account.id == accountId))
          account.id,
    };

    final current = _retainedIn(operations, period, scope);
    final previous = _retainedIn(operations, period.previous, scope);

    final expenses = _total(current, expenses: true);
    final byCategory = _byCategory(
      current: current,
      previous: previous,
      categoriesById: categoriesById,
      total: expenses,
    );

    return ExpenseReport(
      period: period,
      currency: currency,
      totals: ReportTotals(
        income: _total(current, expenses: false),
        expenses: expenses,
        previousIncome: _total(previous, expenses: false),
        previousExpenses: _total(previous, expenses: true),
        operationCount: current.length,
        dayCount: period.dayCount,
        monthCount: period.monthCount,
      ),
      byCategory: byCategory,
      byAccount: _byAccount(current, accountsById),
      byMonth: _byMonth(period: period, operations: operations, scope: scope),
      topExpenses: _topExpenses(
        current: current,
        categoriesById: categoriesById,
        accountsById: accountsById,
        total: expenses,
      ),
      trends: _trends(
        period: period,
        operations: operations,
        scope: scope,
        byCategory: byCategory,
      ),
      accountId: accountId,
      accountName: accountId == null ? null : accountsById[accountId]?.name,
    );
  }

  // ---------------------------------------------------------------------
  // Sélection des opérations
  // ---------------------------------------------------------------------

  /// Opérations d'une période, limitées aux comptes du périmètre et aux
  /// revenus / dépenses (les transferts ne sont ni des revenus ni des
  /// dépenses).
  static List<Operation> _retainedIn(
    List<Operation> operations,
    ReportPeriod period,
    Set<String> scope,
  ) => [
    for (final operation in operations)
      if (operation.type.countsInStats &&
          scope.contains(operation.accountId) &&
          period.contains(operation.date))
        operation,
  ];

  static double _total(List<Operation> operations, {required bool expenses}) {
    var total = 0.0;
    for (final operation in operations) {
      if (expenses ? operation.isExpense : operation.isIncome) {
        total += operation.amount;
      }
    }
    return total;
  }

  // ---------------------------------------------------------------------
  // Dépenses par catégorie
  // ---------------------------------------------------------------------

  /// Dépenses regroupées par catégorie **racine** : les sous-catégories
  /// remontent dans leur catégorie parente.
  ///
  /// Les catégories qui n'ont plus de dépense mais qui en avaient sur la
  /// période précédente sont conservées : leur disparition est une information
  /// (baisse de 100 %).
  static List<CategoryBreakdown> _byCategory({
    required List<Operation> current,
    required List<Operation> previous,
    required Map<String, Category> categoriesById,
    required double total,
  }) {
    final amounts = <String, double>{};
    final previousAmounts = <String, double>{};

    _accumulateByCategory(current, amounts, categoriesById);
    _accumulateByCategory(previous, previousAmounts, categoriesById);

    final breakdown = [
      for (final id in {...amounts.keys, ...previousAmounts.keys})
        CategoryBreakdown(
          categoryId: id,
          name: _categoryName(id, categoriesById),
          colorHex: categoriesById[id]?.colorHex ?? fallbackColor,
          iconKey: categoriesById[id]?.iconKey ?? fallbackIconKey,
          amount: amounts[id] ?? 0,
          share: total <= 0 ? 0 : (amounts[id] ?? 0) / total,
          previousAmount: previousAmounts[id] ?? 0,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));

    return breakdown;
  }

  static void _accumulateByCategory(
    List<Operation> operations,
    Map<String, double> target,
    Map<String, Category> categoriesById,
  ) {
    for (final operation in operations) {
      if (!operation.isExpense) continue;
      final id = _rootIdOf(operation.category.id, categoriesById);
      target.update(
        id,
        (value) => value + operation.amount,
        ifAbsent: () => operation.amount,
      );
    }
  }

  /// Identifiant de la catégorie racine d'une catégorie donnée.
  ///
  /// La remontée est bornée pour qu'une donnée incohérente (parent cyclique)
  /// ne bloque pas le calcul.
  static String _rootIdOf(String categoryId, Map<String, Category> byId) {
    var rootId = categoryId;
    var category = byId[categoryId];
    var depth = 0;
    while (category?.parentId != null && depth < 10) {
      rootId = category!.parentId!;
      category = byId[rootId];
      depth++;
    }
    return rootId;
  }

  /// Nom affichable d'une catégorie, y compris si elle a été supprimée depuis.
  static String _categoryName(String id, Map<String, Category> byId) {
    final category = byId[id];
    if (category != null) return category.name;

    // Catégories historiques : les opérations enregistrées avant les
    // catégories personnalisables portent encore leur identifiant.
    for (final legacy in TransactionCategory.values) {
      if (legacy.id == id) return legacy.label;
    }
    return id;
  }

  // ---------------------------------------------------------------------
  // Dépenses par compte
  // ---------------------------------------------------------------------

  static List<AccountBreakdown> _byAccount(
    List<Operation> operations,
    Map<String, Account> accountsById,
  ) {
    final expenses = <String, double>{};
    final income = <String, double>{};
    final counts = <String, int>{};

    for (final operation in operations) {
      final id = operation.accountId;
      counts.update(id, (value) => value + 1, ifAbsent: () => 1);
      final target = operation.isIncome ? income : expenses;
      target.update(
        id,
        (value) => value + operation.amount,
        ifAbsent: () => operation.amount,
      );
    }

    final breakdown = [
      for (final id in counts.keys)
        AccountBreakdown(
          accountId: id,
          name: accountsById[id]?.name ?? 'Compte',
          type: accountsById[id]?.type ?? AccountType.cash,
          expenses: expenses[id] ?? 0,
          income: income[id] ?? 0,
          operationCount: counts[id] ?? 0,
        ),
    ]..sort((a, b) => b.expenses.compareTo(a.expenses));

    return breakdown;
  }

  // ---------------------------------------------------------------------
  // Comparaison mois par mois
  // ---------------------------------------------------------------------

  /// Revenus et dépenses de chaque mois couvert, avec la variation par rapport
  /// au mois précédent.
  static List<MonthlyComparison> _byMonth({
    required ReportPeriod period,
    required List<Operation> operations,
    required Set<String> scope,
  }) {
    final totals = _monthlyTotals(operations, scope);

    return [
      for (final month in period.months)
        MonthlyComparison(
          month: month,
          income: totals[month]?.income ?? 0,
          expenses: totals[month]?.expenses ?? 0,
          // `null` lorsque le mois précédent est hors de la fenêtre analysée :
          // l'écran affiche alors « — » plutôt qu'une variation trompeuse.
          previousExpenses:
              totals[DateTime(month.year, month.month - 1)]?.expenses,
        ),
    ];
  }

  /// Revenus et dépenses agrégés par mois.
  static Map<DateTime, ({double income, double expenses})> _monthlyTotals(
    List<Operation> operations,
    Set<String> scope,
  ) {
    final totals = <DateTime, ({double income, double expenses})>{};

    for (final operation in operations) {
      if (!operation.type.countsInStats ||
          !scope.contains(operation.accountId)) {
        continue;
      }
      final key = DateTime(operation.date.year, operation.date.month);
      final current = totals[key] ?? (income: 0, expenses: 0);
      totals[key] = operation.isIncome
          ? (
              income: current.income + operation.amount,
              expenses: current.expenses,
            )
          : (
              income: current.income,
              expenses: current.expenses + operation.amount,
            );
    }
    return totals;
  }

  // ---------------------------------------------------------------------
  // Top des dépenses
  // ---------------------------------------------------------------------

  static List<TopExpense> _topExpenses({
    required List<Operation> current,
    required Map<String, Category> categoriesById,
    required Map<String, Account> accountsById,
    required double total,
  }) {
    final ranked = [
      for (final operation in current)
        if (operation.isExpense) operation,
    ]..sort((a, b) => b.amount.compareTo(a.amount));

    return [
      for (final operation in ranked.take(topExpenseCount))
        _topExpenseOf(operation, categoriesById, accountsById, total),
    ];
  }

  static TopExpense _topExpenseOf(
    Operation operation,
    Map<String, Category> categoriesById,
    Map<String, Account> accountsById,
    double total,
  ) {
    final rootId = _rootIdOf(operation.category.id, categoriesById);
    final category = categoriesById[rootId];

    return TopExpense(
      operationId: operation.id,
      label: operation.label,
      amount: operation.amount,
      date: operation.date,
      categoryName: _categoryName(rootId, categoriesById),
      categoryColorHex: category?.colorHex ?? fallbackColor,
      categoryIconKey: category?.iconKey ?? fallbackIconKey,
      accountName: accountsById[operation.accountId]?.name ?? 'Compte',
      share: total <= 0 ? 0 : operation.amount / total,
    );
  }

  // ---------------------------------------------------------------------
  // Tendances
  // ---------------------------------------------------------------------

  /// Tendance de fond : moyenne des trois derniers mois comparée aux trois
  /// précédents, plus les catégories qui ont le plus bougé.
  static TrendAnalysis _trends({
    required ReportPeriod period,
    required List<Operation> operations,
    required Set<String> scope,
    required List<CategoryBreakdown> byCategory,
  }) {
    final expensesByMonth = {
      for (final entry in _monthlyTotals(operations, scope).entries)
        entry.key: entry.value.expenses,
    };

    final endMonth = DateTime(period.end.year, period.end.month);
    final points = [
      for (var offset = trendMonths - 1; offset >= 0; offset--)
        _trendPoint(
          month: DateTime(endMonth.year, endMonth.month - offset),
          expensesByMonth: expensesByMonth,
        ),
    ];

    return TrendAnalysis(
      points: points,
      movers: _movers(byCategory),
      direction: _direction(
        _averageOf(expensesByMonth, endMonth, averageMonths),
        _averageOf(
          expensesByMonth,
          DateTime(endMonth.year, endMonth.month - averageMonths),
          averageMonths,
        ),
      ),
      averageRecent: _averageOf(expensesByMonth, endMonth, averageMonths),
      averagePrevious: _averageOf(
        expensesByMonth,
        DateTime(endMonth.year, endMonth.month - averageMonths),
        averageMonths,
      ),
    );
  }

  static TrendPoint _trendPoint({
    required DateTime month,
    required Map<DateTime, double> expensesByMonth,
  }) {
    var window = 0.0;
    for (var offset = -2; offset <= 0; offset++) {
      window +=
          expensesByMonth[DateTime(month.year, month.month + offset)] ?? 0;
    }

    return TrendPoint(
      month: month,
      amount: expensesByMonth[month] ?? 0,
      movingAverage: window / 3,
    );
  }

  /// Moyenne mensuelle des [count] mois qui se terminent à [until].
  static double _averageOf(
    Map<DateTime, double> expensesByMonth,
    DateTime until,
    int count,
  ) {
    var total = 0.0;
    for (var offset = 0; offset < count; offset++) {
      total += expensesByMonth[DateTime(until.year, until.month - offset)] ?? 0;
    }
    return total / count;
  }

  static TrendDirection _direction(double recent, double previous) {
    if (previous.abs() < 0.005) {
      return recent < 0.005 ? TrendDirection.stable : TrendDirection.up;
    }
    final ratio = (recent - previous) / previous.abs();
    if (ratio.abs() < stableThreshold) return TrendDirection.stable;
    return ratio > 0 ? TrendDirection.up : TrendDirection.down;
  }

  /// Catégories ayant le plus bougé, en valeur absolue.
  static List<CategoryBreakdown> _movers(List<CategoryBreakdown> byCategory) {
    final movers = [
      for (final item in byCategory)
        if (item.amount > 0.005 || item.previousAmount > 0.005) item,
    ]..sort((a, b) => b.variation.abs().compareTo(a.variation.abs()));

    return movers.take(maxMovers).toList(growable: false);
  }
}

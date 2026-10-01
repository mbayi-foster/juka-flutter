import 'package:flutter_test/flutter_test.dart';
import 'package:juka/common/enums/account_type.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/common/enums/transaction_category.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/categories/domain/entities/category.dart';
import 'package:juka/features/categories/domain/enums/category_kind.dart';
import 'package:juka/features/operations/domain/entities/operation.dart';
import 'package:juka/features/reports/domain/entities/report_period.dart';
import 'package:juka/features/reports/domain/enums/report_period_preset.dart';
import 'package:juka/features/reports/domain/enums/trend_direction.dart';
import 'package:juka/features/reports/domain/services/reports_calculator.dart';

/// Septembre 2026, la période analysée par la plupart des tests.
final _september = ReportPeriod(
  start: DateTime(2026, 9),
  end: DateTime(2026, 9, 30, 23, 59, 59),
  preset: ReportPeriodPreset.thisMonth,
);

Account _account(String id, {AppCurrency currency = AppCurrency.eur}) =>
    Account(
      id: id,
      name: 'Compte $id',
      type: AccountType.bank,
      currency: currency,
      initialBalance: 0,
      currentBalance: 0,
      createdAt: DateTime(2026),
    );

Category _category(String id, {String? parentId}) => Category(
  id: id,
  name: id,
  kind: CategoryKind.expense,
  iconKey: 'other',
  colorHex: 0xFF8A8A8A,
  createdAt: DateTime(2026),
  parentId: parentId,
);

Operation _operation({
  required String id,
  required OperationType type,
  required double amount,
  required TransactionCategory category,
  required DateTime date,
  String accountId = 'courant',
  String? transferAccountId,
}) => Operation(
  id: id,
  label: id,
  type: type,
  amount: amount,
  category: category,
  accountId: accountId,
  date: date,
  transferAccountId: transferAccountId,
);

void main() {
  group('ReportsCalculator', () {
    test('regroupe les sous-catégories dans leur catégorie parente', () {
      final report = ReportsCalculator.build(
        period: _september,
        operations: [
          _operation(
            id: 'loyer',
            type: OperationType.expense,
            amount: 800,
            category: TransactionCategory.housing,
            date: DateTime(2026, 9, 5),
          ),
          _operation(
            id: 'courses',
            type: OperationType.expense,
            amount: 60,
            category: TransactionCategory.food,
            date: DateTime(2026, 9, 8),
          ),
          // Sous-catégorie : doit remonter dans « food ».
          _operation(
            id: 'restaurant',
            type: OperationType.expense,
            amount: 40,
            category: TransactionCategory.restaurants,
            date: DateTime(2026, 9, 12),
          ),
          // Mois précédent, pour la variation.
          _operation(
            id: 'courses-aout',
            type: OperationType.expense,
            amount: 200,
            category: TransactionCategory.food,
            date: DateTime(2026, 8, 8),
          ),
        ],
        categories: [
          _category('housing'),
          _category('food'),
          _category('restaurants', parentId: 'food'),
        ],
        accounts: [_account('courant')],
        currency: AppCurrency.eur,
      );

      expect(report.totals.expenses, 900);
      expect(report.byCategory.first.name, 'housing');

      final food = report.byCategory.firstWhere(
        (item) => item.categoryId == 'food',
      );
      expect(food.amount, 100);
      expect(food.share, closeTo(100 / 900, 0.0001));
      expect(food.previousAmount, 200);
      expect(food.variationRatio, closeTo(-0.5, 0.0001));
    });

    test('ignore les transferts et les autres devises', () {
      final report = ReportsCalculator.build(
        period: _september,
        operations: [
          _operation(
            id: 'salaire',
            type: OperationType.income,
            amount: 3000,
            category: TransactionCategory.salary,
            date: DateTime(2026, 9, 1),
            accountId: 'courant',
          ),
          _operation(
            id: 'transfert',
            type: OperationType.transfer,
            amount: 500,
            category: TransactionCategory.transfer,
            date: DateTime(2026, 9, 3),
            accountId: 'courant',
            transferAccountId: 'epargne',
          ),
          _operation(
            id: 'depense-epargne',
            type: OperationType.expense,
            amount: 100,
            category: TransactionCategory.food,
            date: DateTime(2026, 9, 9),
            accountId: 'epargne',
          ),
          // Compte en francs CFA : hors du rapport en euros.
          _operation(
            id: 'depense-cfa',
            type: OperationType.expense,
            amount: 90_000,
            category: TransactionCategory.food,
            date: DateTime(2026, 9, 10),
            accountId: 'mobile',
          ),
        ],
        categories: [_category('food')],
        accounts: [
          _account('courant'),
          _account('epargne'),
          _account('mobile', currency: AppCurrency.xof),
        ],
        currency: AppCurrency.eur,
      );

      expect(report.totals.income, 3000);
      expect(report.totals.expenses, 100);
      expect(report.totals.operationCount, 2);
      expect(report.byAccount.map((item) => item.accountId), [
        'epargne',
        'courant',
      ]);

      final scoped = ReportsCalculator.build(
        period: _september,
        operations: [],
        categories: const [],
        accounts: [_account('courant')],
        currency: AppCurrency.eur,
        accountId: 'courant',
      );
      expect(scoped.isEmpty, isTrue);
      expect(scoped.scopeLabel, 'Compte courant');
    });

    test('compare les mois et déduit une tendance à la baisse', () {
      final report = ReportsCalculator.build(
        period: _september,
        operations: [
          for (final (index, month) in [4, 5, 6, 7, 8, 9].indexed)
            _operation(
              id: 'mois-$month',
              type: OperationType.expense,
              amount: switch (index) {
                < 3 => 500,
                3 => 300,
                4 => 200,
                _ => 100,
              },
              category: TransactionCategory.food,
              date: DateTime(2026, month, 15),
            ),
        ],
        categories: [_category('food')],
        accounts: [_account('courant')],
        currency: AppCurrency.eur,
      );

      expect(report.byMonth.length, 1);
      expect(report.byMonth.single.expenses, 100);
      expect(report.byMonth.single.previousExpenses, 200);

      expect(report.trends.points.length, ReportsCalculator.trendMonths);
      expect(report.trends.points.last.amount, 100);
      expect(report.trends.averageRecent, closeTo(200, 0.0001));
      expect(report.trends.averagePrevious, closeTo(500, 0.0001));
      expect(report.trends.direction, TrendDirection.down);
      expect(report.trends.changeRatio, closeTo(-0.6, 0.0001));
      expect(report.period.previous.start, DateTime(2026, 8));
      expect(report.period.previous.end, DateTime(2026, 8, 31, 23, 59, 59));
    });
  });

  group('ReportsCalculator.resolveCurrency', () {
    Account account(String id, AppCurrency currency, {double balance = 0}) =>
        Account(
          id: id,
          name: id,
          type: AccountType.bank,
          currency: currency,
          initialBalance: balance,
          currentBalance: balance,
          createdAt: DateTime(2026),
        );

    test('sans choix, retient la devise qui porte les opérations', () {
      final operations = [
        _operation(
          id: 'courses',
          type: OperationType.expense,
          amount: 50,
          category: TransactionCategory.food,
          date: DateTime(2026, 9, 10),
          accountId: 'usd',
        ),
      ];

      final currency = ReportsCalculator.resolveCurrency(
        operations: operations,
        // Le compte CDF pèse pourtant beaucoup plus lourd.
        accounts: [
          account('cdf', AppCurrency.cdf, balance: 2000000),
          account('usd', AppCurrency.usd, balance: 40),
        ],
        period: _september,
        fallback: AppCurrency.cdf,
      );

      expect(currency, AppCurrency.usd);
    });

    test('respecte la devise choisie par l\'utilisateur', () {
      final currency = ReportsCalculator.resolveCurrency(
        operations: const [],
        accounts: [account('usd', AppCurrency.usd)],
        period: _september,
        fallback: AppCurrency.cdf,
        requested: AppCurrency.usd,
      );

      expect(currency, AppCurrency.usd);
    });

    test('ignore une opération hors période et retombe sur le repli', () {
      final currency = ReportsCalculator.resolveCurrency(
        operations: [
          _operation(
            id: 'ancienne',
            type: OperationType.expense,
            amount: 50,
            category: TransactionCategory.food,
            date: DateTime(2026, 7, 10),
            accountId: 'usd',
          ),
        ],
        accounts: [
          account('cdf', AppCurrency.cdf, balance: 100),
          account('usd', AppCurrency.usd, balance: 10),
        ],
        period: _september,
        fallback: AppCurrency.cdf,
      );

      expect(currency, AppCurrency.cdf);
    });
  });
}

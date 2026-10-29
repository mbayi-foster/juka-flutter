import 'package:flutter_test/flutter_test.dart';
import 'package:juka/common/enums/account_type.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/common/enums/transaction_category.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:juka/features/categories/data/datasources/default_categories.dart';
import 'package:juka/features/categories/domain/entities/budget.dart';
import 'package:juka/features/categories/domain/entities/category.dart';
import 'package:juka/features/categories/domain/repositories/categories_repository.dart';
import 'package:juka/features/currencies/domain/entities/exchange_rate.dart';
import 'package:juka/features/currencies/domain/services/currency_converter.dart';
import 'package:juka/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:juka/features/dashboard/domain/entities/dashboard_alert.dart';
import 'package:juka/features/operations/domain/entities/operation.dart';
import 'package:juka/features/operations/domain/entities/operation_filter.dart';
import 'package:juka/features/operations/domain/repositories/operations_repository.dart';
import 'package:juka/features/wealth/domain/entities/net_worth_snapshot.dart';
import 'package:juka/features/wealth/domain/repositories/wealth_repository.dart';

class _FakeAccounts implements AccountsRepository {
  _FakeAccounts(this.accounts);

  final List<Account> accounts;

  @override
  Future<List<Account>> fetchAccounts() async => accounts;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOperations implements OperationsRepository {
  _FakeOperations(this.operations);

  final List<Operation> operations;

  @override
  Future<List<Operation>> fetchOperations(OperationFilter filter) async =>
      operations;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCategories implements CategoriesRepository {
  _FakeCategories({required this.categories, this.budgets = const {}});

  final List<Category> categories;
  final Map<String, Budget> budgets;

  @override
  Future<List<Category>> ensureDefaults() async => categories;

  @override
  Future<Map<String, Budget>> fetchBudgets() async => budgets;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWealth implements WealthRepository {
  _FakeWealth({List<NetWorthSnapshot> snapshots = const []})
    : _snapshots = [...snapshots];

  final List<NetWorthSnapshot> _snapshots;
  final List<NetWorthSnapshot> saved = [];

  @override
  Future<NetWorthSnapshot> saveSnapshot(NetWorthSnapshot snapshot) async {
    saved.add(snapshot);
    _snapshots.removeWhere(
      (item) =>
          item.currency == snapshot.currency &&
          item.isSameMonth(snapshot.month),
    );
    _snapshots.add(snapshot);
    return snapshot;
  }

  @override
  Future<List<NetWorthSnapshot>> fetchSnapshots({
    required AppCurrency currency,
    int? limit,
  }) async {
    final filtered =
        _snapshots.where((item) => item.currency == currency).toList()
          ..sort((a, b) => a.month.compareTo(b.month));
    if (limit == null || filtered.length <= limit) return filtered;
    return filtered.sublist(filtered.length - limit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Account _account({
  required String id,
  required AppCurrency currency,
  required double balance,
  AccountType type = AccountType.bank,
  bool archived = false,
}) => Account(
  id: id,
  name: id,
  type: type,
  currency: currency,
  initialBalance: balance,
  currentBalance: balance,
  createdAt: DateTime(2020),
  isArchived: archived,
);

Operation _operation({
  required String id,
  required OperationType type,
  required TransactionCategory category,
  required double amount,
  required String accountId,
  required DateTime date,
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

NetWorthSnapshot _snapshot(
  DateTime month,
  AppCurrency currency,
  double netWorth,
) => NetWorthSnapshot(
  month: DateTime(month.year, month.month),
  currency: currency,
  assets: netWorth,
  liabilities: 0,
  recordedAt: month,
);

void main() {
  final now = DateTime.now();
  final thisMonth = DateTime(now.year, now.month, 10);
  final prevMonth = DateTime(now.year, now.month - 1, 10);

  final categories = DefaultCategories.build();

  DashboardRepositoryImpl build({
    required List<Account> accounts,
    required List<Operation> operations,
    List<Category>? categoryList,
    Map<String, Budget> budgets = const {},
    List<NetWorthSnapshot> snapshots = const [],
    _FakeWealth? wealth,
    CurrencyConverter? converter,
  }) => DashboardRepositoryImpl(
    accountsRepository: _FakeAccounts(accounts),
    operationsRepository: _FakeOperations(operations),
    categoriesRepository: _FakeCategories(
      categories: categoryList ?? categories,
      budgets: budgets,
    ),
    wealthRepository: wealth ?? _FakeWealth(snapshots: snapshots),
    converter: converter,
  );

  group('flux du mois', () {
    test('exclut les transferts et se limite à la devise affichée', () async {
      final overview = await build(
        accounts: [
          _account(id: 'a1', currency: AppCurrency.eur, balance: 1000),
          _account(id: 'a2', currency: AppCurrency.usd, balance: 500),
        ],
        operations: [
          _operation(
            id: 'op1',
            type: OperationType.expense,
            category: TransactionCategory.food,
            amount: 60,
            accountId: 'a1',
            date: thisMonth,
          ),
          _operation(
            id: 'op2',
            type: OperationType.income,
            category: TransactionCategory.salary,
            amount: 200,
            accountId: 'a1',
            date: thisMonth,
          ),
          _operation(
            id: 'op3',
            type: OperationType.transfer,
            category: TransactionCategory.transfer,
            amount: 50,
            accountId: 'a1',
            date: thisMonth,
            transferAccountId: 'a2',
          ),
          _operation(
            id: 'op4',
            type: OperationType.expense,
            category: TransactionCategory.food,
            amount: 40,
            accountId: 'a2',
            date: thisMonth,
          ),
          _operation(
            id: 'op5',
            type: OperationType.expense,
            category: TransactionCategory.food,
            amount: 30,
            accountId: 'a1',
            date: prevMonth,
          ),
        ],
      ).fetchOverview();

      expect(overview.currency, AppCurrency.eur);
      expect(overview.accountCount, 1);
      expect(overview.flow.income, 200);
      expect(overview.flow.expenses, 60);
      expect(overview.spendingByCategory, hasLength(1));
      expect(overview.spendingByCategory.single.amount, 60);
      expect(overview.recentOperations.map((operation) => operation.id), [
        'op1',
        'op2',
        'op3',
      ]);
    });

    test(
      'les revenus et dépenses totalisent la répartition des dépenses',
      () async {
        final overview = await build(
          accounts: [
            _account(id: 'a1', currency: AppCurrency.eur, balance: 1000),
          ],
          operations: [
            _operation(
              id: 'op1',
              type: OperationType.expense,
              category: TransactionCategory.food,
              amount: 60,
              accountId: 'a1',
              date: thisMonth,
            ),
            _operation(
              id: 'op2',
              type: OperationType.expense,
              category: TransactionCategory.housing,
              amount: 40,
              accountId: 'a1',
              date: thisMonth,
            ),
          ],
        ).fetchOverview();

        expect(overview.totalExpenses, overview.flow.expenses);
        expect(overview.totalExpenses, 100);
      },
    );

    test(
      'compte une dépense dont la catégorie par défaut a été supprimée',
      () async {
        final overview = await build(
          accounts: [
            _account(id: 'a1', currency: AppCurrency.eur, balance: 1000),
          ],
          categoryList: [
            for (final category in DefaultCategories.build())
              if (category.id != 'housing') category,
          ],
          operations: [
            _operation(
              id: 'op1',
              type: OperationType.expense,
              category: TransactionCategory.food,
              amount: 60,
              accountId: 'a1',
              date: thisMonth,
            ),
            _operation(
              id: 'op2',
              type: OperationType.expense,
              category: TransactionCategory.housing,
              amount: 40,
              accountId: 'a1',
              date: thisMonth,
            ),
          ],
        ).fetchOverview();

        expect(overview.flow.expenses, 100);
        expect(overview.totalExpenses, 100);
      },
    );

    test(
      'compte une opération datée de la dernière milliseconde du mois',
      () async {
        final lastInstant = DateTime(
          now.year,
          now.month + 1,
          0,
          23,
          59,
          59,
          500,
        );

        final overview = await build(
          accounts: [
            _account(id: 'a1', currency: AppCurrency.eur, balance: 1000),
          ],
          operations: [
            _operation(
              id: 'op1',
              type: OperationType.expense,
              category: TransactionCategory.food,
              amount: 60,
              accountId: 'a1',
              date: lastInstant,
            ),
          ],
        ).fetchOverview();

        expect(overview.flow.expenses, 60);
      },
    );
  });

  group('budgets', () {
    test('reporte le reste du mois précédent', () async {
      final overview = await build(
        accounts: [
          _account(id: 'a1', currency: AppCurrency.eur, balance: 1000),
        ],
        budgets: {
          'food': const Budget(
            categoryId: 'food',
            monthlyLimit: 100,
            carryOver: true,
          ),
        },
        operations: [
          _operation(
            id: 'op1',
            type: OperationType.expense,
            category: TransactionCategory.food,
            amount: 60,
            accountId: 'a1',
            date: thisMonth,
          ),
          _operation(
            id: 'op2',
            type: OperationType.expense,
            category: TransactionCategory.food,
            amount: 30,
            accountId: 'a1',
            date: prevMonth,
          ),
        ],
      ).fetchOverview();

      expect(overview.budgets, hasLength(1));
      expect(overview.budgets.single.spent, 60);
      expect(overview.budgets.single.limit, 170);
    });
  });

  group('patrimoine', () {
    test('compare à la photo du mois précédent', () async {
      final overview = await build(
        accounts: [
          _account(id: 'a1', currency: AppCurrency.eur, balance: 1000),
        ],
        operations: const [],
        snapshots: [_snapshot(prevMonth, AppCurrency.eur, 900)],
      ).fetchOverview();

      expect(overview.netWorth.amount, 1000);
      expect(overview.netWorth.previousAmount, 900);
      expect(overview.netWorth.change, 100);
    });

    test('convertit les comptes dans la devise de référence', () async {
      final converter = CurrencyConverter(
        reference: AppCurrency.eur,
        rates: {
          AppCurrency.usd: {
            ExchangeRate.monthKey(thisMonth): 2,
            ExchangeRate.monthKey(prevMonth): 2,
          },
        },
      );

      final wealth = _FakeWealth();
      final overview = await build(
        accounts: [
          _account(id: 'a1', currency: AppCurrency.eur, balance: 100),
          _account(id: 'a2', currency: AppCurrency.usd, balance: 200),
        ],
        operations: const [],
        wealth: wealth,
        converter: converter,
      ).fetchOverview();

      expect(overview.currency, AppCurrency.eur);
      expect(overview.accountCount, 2);
      expect(overview.netWorth.amount, 500);
      expect(wealth.saved, hasLength(1));
      expect(wealth.saved.single.currency, AppCurrency.eur);
      expect(wealth.saved.single.netWorth, 500);
    });
  });

  group('alertes', () {
    test('signale un budget dépassé', () async {
      final overview = await build(
        accounts: [
          _account(id: 'a1', currency: AppCurrency.eur, balance: 1000),
        ],
        budgets: {'food': const Budget(categoryId: 'food', monthlyLimit: 50)},
        operations: [
          _operation(
            id: 'op1',
            type: OperationType.expense,
            category: TransactionCategory.food,
            amount: 60,
            accountId: 'a1',
            date: thisMonth,
          ),
        ],
      ).fetchOverview();

      expect(
        overview.alerts.any((alert) => alert.severity == AlertSeverity.danger),
        isTrue,
      );
    });

    test('signale un écart de rapprochement', () async {
      final account = Account(
        id: 'a1',
        name: 'Compte',
        type: AccountType.bank,
        currency: AppCurrency.eur,
        initialBalance: 1000,
        currentBalance: 1000,
        createdAt: DateTime(2020),
        reconciledBalance: 950,
      );

      final overview = await build(
        accounts: [account],
        operations: const [],
      ).fetchOverview();

      expect(
        overview.alerts.any((alert) => alert.title == 'Écart de rapprochement'),
        isTrue,
      );
    });
  });
}

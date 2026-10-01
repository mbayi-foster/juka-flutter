import 'package:flutter_test/flutter_test.dart';
import 'package:juka/common/enums/account_type.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/wealth/domain/services/wealth_calculator.dart';

Account _account({
  required String id,
  required AppCurrency currency,
  double balance = 0,
  bool isArchived = false,
}) => Account(
  id: id,
  name: id,
  type: AccountType.bank,
  currency: currency,
  initialBalance: balance,
  currentBalance: balance,
  createdAt: DateTime(2026),
  isArchived: isArchived,
);

void main() {
  group('WealthCalculator.primaryCurrency', () {
    test('sans activité, retient la devise qui pèse le plus', () {
      final currency = WealthCalculator.primaryCurrency([
        _account(id: 'cdf', currency: AppCurrency.cdf, balance: 2000000),
        _account(id: 'usd', currency: AppCurrency.usd, balance: 40),
      ]);

      expect(currency, AppCurrency.cdf);
    });

    test('préfère la devise active, même si elle pèse moins lourd', () {
      final currency = WealthCalculator.primaryCurrency(
        [
          _account(id: 'cdf', currency: AppCurrency.cdf, balance: 2000000),
          _account(id: 'usd', currency: AppCurrency.usd, balance: 40),
        ],
        operationCounts: {AppCurrency.usd: 3, AppCurrency.cdf: 0},
      );

      expect(currency, AppCurrency.usd);
    });

    test('ignore les comptes archivés et une devise sans compte', () {
      final currency = WealthCalculator.primaryCurrency(
        [
          _account(id: 'cdf', currency: AppCurrency.cdf, balance: 10),
          _account(
            id: 'ancien',
            currency: AppCurrency.usd,
            balance: 999999,
            isArchived: true,
          ),
        ],
        // Aucun compte actif en USD : la devise est ignorée.
        operationCounts: {AppCurrency.usd: 5},
      );

      expect(currency, AppCurrency.cdf);
    });

    test('renvoie null sans compte actif', () {
      expect(WealthCalculator.primaryCurrency(const []), isNull);
      expect(
        WealthCalculator.primaryCurrency([
          _account(
            id: 'ancien',
            currency: AppCurrency.eur,
            balance: 100,
            isArchived: true,
          ),
        ]),
        isNull,
      );
    });
  });
}

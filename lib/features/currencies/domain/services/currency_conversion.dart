import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/currencies/domain/services/currency_converter.dart';
import 'package:juka/features/operations/domain/entities/operation.dart';

/// Applique une conversion de devise aux données brutes.
///
/// Le tableau de bord et les rapports convertissent ainsi leurs comptes et
/// leurs opérations **avant** de les confier aux calculateurs : ceux-ci
/// continuent de ne raisonner que sur une seule devise, sans connaître les taux
/// de change.
abstract final class CurrencyConversion {
  /// Comptes ramenés dans la devise de référence.
  ///
  /// Un compte dont la devise n'a pas encore de taux est écarté : mieux vaut un
  /// total incomplet mais juste qu'un total faux. L'écran des devises signale
  /// les taux manquants.
  static List<Account> accounts(
    List<Account> accounts,
    CurrencyConverter converter,
    DateTime month,
  ) {
    final converted = <Account>[];

    for (final account in accounts) {
      final rate = converter.rateOf(account.currency, month);
      if (rate == null) continue;

      final reconciled = account.reconciledBalance;
      converted.add(
        account.copyWith(
          currency: converter.reference,
          initialBalance: account.initialBalance * rate,
          currentBalance: account.currentBalance * rate,
          reconciledBalance: reconciled == null ? null : reconciled * rate,
        ),
      );
    }

    return converted;
  }

  /// Opérations ramenées dans la devise de référence, au taux du mois de chaque
  /// opération.
  static List<Operation> operations(
    List<Operation> operations,
    CurrencyConverter converter,
    List<Account> accounts,
  ) {
    final currencyByAccount = {
      for (final account in accounts) account.id: account.currency,
    };
    final converted = <Operation>[];

    for (final operation in operations) {
      final currency = currencyByAccount[operation.accountId];
      if (currency == null) continue;

      final amount = converter.convert(
        operation.amount,
        currency,
        operation.date,
      );
      if (amount == null) continue;
      converted.add(operation.copyWith(amount: amount));
    }

    return converted;
  }
}

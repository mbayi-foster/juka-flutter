import 'package:juka/common/enums/account_type.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/data/datasources/accounts_local_data_source.dart';
import 'package:juka/features/accounts/data/exceptions/accounts_exception.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/accounts/domain/entities/account_balance_point.dart';
import 'package:juka/features/accounts/domain/failures/accounts_failure.dart';
import 'package:juka/features/accounts/domain/repositories/accounts_repository.dart';

/// Implémentation du contrat [AccountsRepository] au-dessus de la source
/// locale, en attendant la base de données ou les endpoints de `api-juka`.
///
/// Elle traduit les [AccountsException] techniques en [AccountsFailure] métier.
class AccountsRepositoryImpl implements AccountsRepository {
  const AccountsRepositoryImpl(this._localDataSource);

  final AccountsLocalDataSource _localDataSource;

  static const String _unexpectedMessage =
      'Une erreur inattendue est survenue. Veuillez réessayer.';

  @override
  Future<List<Account>> fetchAccounts() =>
      _guard(_localDataSource.fetchAccounts);

  @override
  Future<List<AccountBalancePoint>> fetchBalanceHistory(String accountId) =>
      _guard(() => _localDataSource.fetchBalanceHistory(accountId));

  @override
  Future<Account> createAccount({
    required String name,
    required AccountType type,
    required AppCurrency currency,
    required double initialBalance,
    String? note,
  }) {
    return _guard(
      () => _localDataSource.createAccount(
        name: name,
        type: type,
        currency: currency,
        initialBalance: initialBalance,
        note: note,
      ),
    );
  }

  @override
  Future<Account> updateAccount({
    required String id,
    required String name,
    required AccountType type,
    required AppCurrency currency,
    required double initialBalance,
    String? note,
  }) {
    return _guard(
      () => _localDataSource.updateAccount(
        id: id,
        name: name,
        type: type,
        currency: currency,
        initialBalance: initialBalance,
        note: note,
      ),
    );
  }

  @override
  Future<Account> setArchived({required String id, required bool isArchived}) {
    return _guard(
      () => _localDataSource.setArchived(id: id, isArchived: isArchived),
    );
  }

  @override
  Future<Account> reconcile({required String id, required double realBalance}) {
    return _guard(
      () => _localDataSource.reconcile(id: id, realBalance: realBalance),
    );
  }

  /// Exécute [action] et convertit les erreurs techniques en [AccountsFailure].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AccountsException catch (exception) {
      throw AccountsFailure(exception.message);
    } catch (_) {
      throw const AccountsFailure(_unexpectedMessage);
    }
  }
}

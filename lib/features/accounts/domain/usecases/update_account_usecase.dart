import 'package:juka/common/enums/account_type.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/accounts/domain/repositories/accounts_repository.dart';

/// Modifie un compte existant (nom, type, devise, solde initial, note).
class UpdateAccountUseCase {
  const UpdateAccountUseCase(this._repository);

  final AccountsRepository _repository;

  Future<Account> call({
    required String id,
    required String name,
    required AccountType type,
    required AppCurrency currency,
    required double initialBalance,
    String? note,
  }) {
    return _repository.updateAccount(
      id: id,
      name: name,
      type: type,
      currency: currency,
      initialBalance: initialBalance,
      note: note,
    );
  }
}

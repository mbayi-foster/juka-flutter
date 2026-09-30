import 'package:juka/features/accounts/domain/entities/account_balance_point.dart';
import 'package:juka/features/accounts/domain/repositories/accounts_repository.dart';

/// Récupère l'historique du solde d'un compte.
class GetAccountBalanceHistoryUseCase {
  const GetAccountBalanceHistoryUseCase(this._repository);

  final AccountsRepository _repository;

  Future<List<AccountBalancePoint>> call(String accountId) =>
      _repository.fetchBalanceHistory(accountId);
}

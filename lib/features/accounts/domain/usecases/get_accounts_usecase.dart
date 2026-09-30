import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/accounts/domain/repositories/accounts_repository.dart';

/// Récupère tous les comptes de l'utilisateur.
class GetAccountsUseCase {
  const GetAccountsUseCase(this._repository);

  final AccountsRepository _repository;

  Future<List<Account>> call() => _repository.fetchAccounts();
}

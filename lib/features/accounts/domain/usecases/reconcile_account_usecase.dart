import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/accounts/domain/repositories/accounts_repository.dart';

/// Enregistre le rapprochement d'un compte avec son solde réel.
class ReconcileAccountUseCase {
  const ReconcileAccountUseCase(this._repository);

  final AccountsRepository _repository;

  Future<Account> call({required String id, required double realBalance}) =>
      _repository.reconcile(id: id, realBalance: realBalance);
}

import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/accounts/domain/repositories/accounts_repository.dart';

/// Archive un compte (ou le restaure) sans supprimer son historique.
class SetAccountArchivedUseCase {
  const SetAccountArchivedUseCase(this._repository);

  final AccountsRepository _repository;

  Future<Account> call({required String id, required bool isArchived}) =>
      _repository.setArchived(id: id, isArchived: isArchived);
}

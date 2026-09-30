import 'package:juka/features/operations/domain/entities/operation.dart';
import 'package:juka/features/operations/domain/failures/operations_failure.dart';
import 'package:juka/features/operations/domain/repositories/operations_repository.dart';

/// Enregistre un transfert d'argent entre deux comptes.
///
/// Un transfert n'est ni un revenu ni une dépense : il ne dégrade pas les
/// statistiques de dépenses, il déplace seulement le solde.
class CreateTransferUseCase {
  const CreateTransferUseCase(this._repository);

  final OperationsRepository _repository;

  Future<Operation> call({
    required String label,
    required double amount,
    required String fromAccountId,
    required String toAccountId,
    required DateTime date,
    String? note,
  }) {
    if (fromAccountId == toAccountId) {
      throw const OperationsFailure(
        'Choisissez deux comptes différents pour le transfert.',
      );
    }

    return _repository.createTransfer(
      label: label,
      amount: amount,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      date: date,
      note: note,
    );
  }
}

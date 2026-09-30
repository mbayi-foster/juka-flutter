import 'package:juka/features/operations/domain/entities/operation_attachment.dart';
import 'package:juka/features/operations/domain/enums/attachment_source.dart';
import 'package:juka/features/operations/domain/repositories/operations_repository.dart';
import 'package:juka/features/operations/domain/services/attachment_storage.dart';

/// Rattache une photo de reçu à une opération.
///
/// La photo est d'abord copiée dans le stockage privé de l'application (elle
/// n'apparaît pas dans la galerie du téléphone), puis seul son **chemin** est
/// enregistré en base.
class AttachReceiptUseCase {
  const AttachReceiptUseCase(this._storage, this._repository);

  final AttachmentStorage _storage;
  final OperationsRepository _repository;

  Future<OperationAttachment> call({
    required String operationId,
    required AttachmentSource source,
  }) async {
    final imported = await _storage.importReceipt(
      operationId: operationId,
      source: source,
    );
    return _repository.saveAttachment(imported);
  }
}

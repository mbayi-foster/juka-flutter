import 'package:juka/features/operations/domain/entities/operation_attachment.dart';
import 'package:juka/features/operations/domain/repositories/operations_repository.dart';
import 'package:juka/features/operations/domain/services/attachment_storage.dart';

/// Supprime une pièce jointe : d'abord la référence en base, puis le fichier
/// du stockage privé.
class RemoveAttachmentUseCase {
  const RemoveAttachmentUseCase(this._repository, this._storage);

  final OperationsRepository _repository;
  final AttachmentStorage _storage;

  Future<void> call(OperationAttachment attachment) async {
    await _repository.deleteAttachment(attachment.id);
    await _storage.delete(attachment);
  }
}

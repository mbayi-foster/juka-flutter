import 'package:juka/features/operations/domain/entities/operation_attachment.dart';
import 'package:juka/features/operations/domain/services/attachment_storage.dart';

/// Exporte une pièce jointe vers la galerie du téléphone.
///
/// Les reçus restent dans le stockage privé de l'application : c'est à
/// l'utilisateur de demander explicitement l'export.
class SaveAttachmentToGalleryUseCase {
  const SaveAttachmentToGalleryUseCase(this._storage);

  final AttachmentStorage _storage;

  Future<void> call(OperationAttachment attachment) =>
      _storage.saveToGallery(attachment);
}

import 'package:juka/features/operations/domain/entities/operation_attachment.dart';
import 'package:juka/features/operations/domain/enums/attachment_source.dart';

/// Contrat d'accès aux fichiers de l'appareil.
///
/// L'implémentation vit dans la couche `data` : le domaine ne connaît ni les
/// plugins (appareil photo, galerie) ni les chemins de stockage.
abstract interface class AttachmentStorage {
  /// Récupère une photo depuis [source] et la **copie dans le stockage privé de
  /// l'application**.
  ///
  /// Le fichier n'est jamais ajouté à la galerie du téléphone. L'entité
  /// retournée n'est pas encore persistée (`isPersisted == false`) :
  /// `OperationsRepository.saveAttachment` se charge d'enregistrer son chemin.
  Future<OperationAttachment> importReceipt({
    required String operationId,
    required AttachmentSource source,
  });

  /// Supprime le fichier du stockage privé.
  Future<void> delete(OperationAttachment attachment);

  /// Exporte la photo vers la galerie du téléphone, à la demande explicite de
  /// l'utilisateur.
  Future<void> saveToGallery(OperationAttachment attachment);
}

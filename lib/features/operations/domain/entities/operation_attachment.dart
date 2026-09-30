/// Pièce jointe d'une opération (photo de reçu).
///
/// Seul le **chemin** du fichier est enregistré en base (SQLite) : le fichier
/// lui-même vit dans le stockage privé de l'application. Il n'apparaît donc
/// jamais dans la galerie du téléphone — l'utilisateur peut en revanche
/// l'exporter explicitement (voir `AttachmentStorage.saveToGallery`).
class OperationAttachment {
  const OperationAttachment({
    required this.id,
    required this.operationId,
    required this.filePath,
    required this.fileName,
    required this.createdAt,
    this.mimeType,
    this.sizeInBytes,
  });

  final String id;

  /// Opération à laquelle la pièce jointe est rattachée.
  final String operationId;

  /// Chemin absolu dans le stockage privé de l'application.
  final String filePath;

  /// Nom du fichier, utile pour l'export ou le partage.
  final String fileName;

  final DateTime createdAt;

  /// Type MIME (`image/jpeg`, `application/pdf`…), `null` si inconnu.
  final String? mimeType;

  /// Taille du fichier en octets, `null` si inconnue.
  final int? sizeInBytes;

  /// Pièce jointe pas encore enregistrée en base.
  bool get isPersisted => id.isNotEmpty;

  bool get isImage => (mimeType ?? '').startsWith('image/');

  OperationAttachment copyWith({
    String? id,
    String? operationId,
    String? filePath,
    String? fileName,
    DateTime? createdAt,
    String? mimeType,
    int? sizeInBytes,
  }) {
    return OperationAttachment(
      id: id ?? this.id,
      operationId: operationId ?? this.operationId,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
      mimeType: mimeType ?? this.mimeType,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
    );
  }
}

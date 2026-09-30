/// Provenance d'une pièce jointe (photo de reçu).
enum AttachmentSource {
  /// Appareil photo de l'appareil.
  camera('Prendre une photo'),

  /// Photothèque de l'appareil.
  gallery('Choisir dans la galerie');

  const AttachmentSource(this.label);

  /// Libellé affichable à l'utilisateur.
  final String label;
}

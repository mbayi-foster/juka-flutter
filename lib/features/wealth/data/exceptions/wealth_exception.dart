/// Erreur technique levée par la couche de données du patrimoine.
///
/// Elle est traduite en `WealthFailure` par le repository, afin que le domaine
/// ne connaisse que des erreurs métier.
class WealthException implements Exception {
  const WealthException(this.message);

  final String message;

  @override
  String toString() => 'WealthException: $message';
}

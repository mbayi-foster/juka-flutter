/// Erreur technique levée par la couche de données des catégories.
///
/// Elle est traduite en `CategoriesFailure` par le repository, afin que le
/// domaine ne connaisse que des erreurs métier.
class CategoriesException implements Exception {
  const CategoriesException(this.message);

  final String message;

  @override
  String toString() => 'CategoriesException: $message';
}

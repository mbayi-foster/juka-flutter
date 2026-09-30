/// Erreur technique levée par la couche de données des opérations.
///
/// Elle est traduite en `OperationsFailure` par le repository, afin que le
/// domaine ne connaisse que des erreurs métier.
class OperationsException implements Exception {
  const OperationsException(this.message);

  final String message;

  @override
  String toString() => 'OperationsException: $message';
}

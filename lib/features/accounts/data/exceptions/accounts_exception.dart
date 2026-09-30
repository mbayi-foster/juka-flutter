/// Erreur technique levée par la couche de données des comptes.
///
/// Elle est traduite en `AccountsFailure` par le repository, afin que le
/// domaine ne connaisse que des erreurs métier.
class AccountsException implements Exception {
  const AccountsException(this.message);

  final String message;

  @override
  String toString() => 'AccountsException: $message';
}

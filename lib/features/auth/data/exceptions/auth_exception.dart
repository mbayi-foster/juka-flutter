/// Erreur technique levée par la couche de données (source distante).
///
/// Elle est traduite en [AuthFailure] par le repository afin que le domaine
/// ne dépende jamais des détails de l'API.
class AuthException implements Exception {
  const AuthException(this.message, {this.code});

  final String message;

  /// Code renvoyé par l'API (ex : `EMAIL_ALREADY_USED`).
  final String? code;

  @override
  String toString() => 'AuthException(${code ?? 'unknown'}): $message';
}

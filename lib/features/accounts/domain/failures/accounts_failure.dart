/// Erreur métier remontée par la couche domaine des comptes.
///
/// Le message est directement affichable à l'utilisateur.
class AccountsFailure implements Exception {
  const AccountsFailure(this.message);

  final String message;

  @override
  String toString() => 'AccountsFailure: $message';
}

/// Solde d'un compte à une date donnée (premier jour du mois).
///
/// Sert à tracer l'historique d'un compte sans dépendre des opérations.
class AccountBalancePoint {
  const AccountBalancePoint({required this.month, required this.balance});

  final DateTime month;
  final double balance;
}

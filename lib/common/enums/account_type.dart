/// Nature d'un compte, du point de vue de l'utilisateur.
enum AccountType {
  bank('Compte bancaire'),
  mobileMoney('Mobile money'),
  cash('Espèces'),
  savings('Épargne'),
  debt('Dette'),
  receivable('Créance');

  const AccountType(this.label);

  /// Libellé affichable à l'utilisateur.
  final String label;

  /// `true` pour les dettes : leur solde doit être saisi en négatif.
  bool get isLiability => this == AccountType.debt;

  /// `true` pour l'argent qu'on nous doit.
  bool get isReceivable => this == AccountType.receivable;
}

import 'package:juka/common/enums/account_type.dart';
import 'package:juka/common/enums/app_currency.dart';

/// Compte de l'utilisateur : là où se trouve son argent.
///
/// Les soldes sont **signés** : une dette ou un découvert est négatif. Les
/// totaux multi-devises ne sont jamais additionnés (les devises sont
/// regroupées via [AppCurrency]).
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.initialBalance,
    required this.currentBalance,
    required this.createdAt,
    this.isArchived = false,
    this.reconciledBalance,
    this.reconciledAt,
    this.note,
  });

  final String id;

  /// Nom donné par l'utilisateur (ex. « Livret A »).
  final String name;

  final AccountType type;
  final AppCurrency currency;

  /// Solde saisi à la création du compte.
  final double initialBalance;

  /// Solde courant, calculé à partir des opérations rattachées au compte.
  final double currentBalance;

  final DateTime createdAt;

  /// Un compte archivé est conservé mais exclu des totaux et de la liste
  /// principale.
  final bool isArchived;

  /// Solde réel constaté lors du dernier rapprochement, `null` si jamais fait.
  final double? reconciledBalance;

  /// Date du dernier rapprochement.
  final DateTime? reconciledAt;

  final String? note;

  /// Écart entre le solde réel constaté et le solde calculé par l'application.
  double? get reconciliationGap =>
      reconciledBalance == null ? null : reconciledBalance! - currentBalance;

  /// `true` si le dernier rapprochement ne révèle aucun écart.
  bool get isReconciled {
    final gap = reconciliationGap;
    return gap != null && gap.abs() < 0.005;
  }

  /// Mouvement cumulé depuis l'ouverture du compte.
  double get movement => currentBalance - initialBalance;

  Account copyWith({
    String? name,
    AccountType? type,
    AppCurrency? currency,
    double? initialBalance,
    double? currentBalance,
    bool? isArchived,
    double? reconciledBalance,
    DateTime? reconciledAt,
    String? note,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt,
      isArchived: isArchived ?? this.isArchived,
      reconciledBalance: reconciledBalance ?? this.reconciledBalance,
      reconciledAt: reconciledAt ?? this.reconciledAt,
      note: note ?? this.note,
    );
  }
}

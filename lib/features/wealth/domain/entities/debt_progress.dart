import 'package:juka/features/accounts/domain/entities/account.dart';

/// Suivi du remboursement d'une dette (compte de type « dette »).
class DebtProgress {
  const DebtProgress({
    required this.account,
    required this.initialDebt,
    required this.remainingDebt,
    this.averageMonthlyPayment = 0,
  });

  final Account account;

  /// Dette constatée à l'ouverture du compte (toujours positif).
  final double initialDebt;

  /// Dette restante aujourd'hui (toujours positif).
  final double remainingDebt;

  /// Remboursement mensuel moyen observé récemment, 0 si inconnu.
  final double averageMonthlyPayment;

  /// Montant déjà remboursé.
  double get repaid {
    final repaid = initialDebt - remainingDebt;
    if (repaid < 0) return 0;
    return repaid > initialDebt ? initialDebt : repaid;
  }

  /// Part remboursée (`0.53` = 53 %).
  double get progress => initialDebt <= 0 ? 0 : repaid / initialDebt;

  /// Dette soldée.
  bool get isRepaid => remainingDebt <= 0.005;

  /// Nombre de mois restants au rythme actuel, `null` si le rythme est inconnu.
  int? get monthsRemaining {
    if (isRepaid) return 0;
    if (averageMonthlyPayment <= 0) return null;
    return (remainingDebt / averageMonthlyPayment).ceil();
  }

  /// Date de fin estimée au rythme actuel, `null` si indéterminée.
  DateTime? estimatedPayoffDate({DateTime? from}) {
    final months = monthsRemaining;
    if (months == null) return null;
    final reference = from ?? DateTime.now();
    return DateTime(reference.year, reference.month + months, reference.day);
  }
}

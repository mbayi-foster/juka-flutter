import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/wealth/domain/entities/debt_progress.dart';
import 'package:juka/features/wealth/domain/entities/net_worth_snapshot.dart';
import 'package:juka/features/wealth/domain/entities/wealth_indicators.dart';

/// Agrégat de l'écran « Patrimoine et progression ».
class WealthOverview {
  const WealthOverview({
    required this.currency,
    required this.current,
    required this.history,
    required this.indicators,
    required this.debts,
    required this.accounts,
    this.previousMonth,
  });

  /// Devise affichée (les devises ne sont pas converties entre elles).
  final AppCurrency currency;

  /// Photo du mois en cours.
  final NetWorthSnapshot current;

  /// Photo du mois précédent, `null` si elle n'a jamais été prise.
  final NetWorthSnapshot? previousMonth;

  /// Photos des derniers mois, du plus ancien au plus récent.
  final List<NetWorthSnapshot> history;

  final WealthIndicators indicators;

  /// Dettes en cours de remboursement.
  final List<DebtProgress> debts;

  /// Comptes qui composent le patrimoine affiché.
  final List<Account> accounts;

  double get netWorth => current.netWorth;

  double get assets => current.assets;

  double get liabilities => current.liabilities;

  /// Variation du patrimoine net depuis le mois précédent.
  double? get change {
    final previous = previousMonth;
    if (previous == null) return null;
    return netWorth - previous.netWorth;
  }

  /// Variation relative (`0.032` = +3,2 %).
  double? get changeRatio {
    final previous = previousMonth;
    final change = this.change;
    if (previous == null || change == null || previous.netWorth == 0) {
      return null;
    }
    return change / previous.netWorth.abs();
  }

  /// `true` lorsque le patrimoine progresse (ou reste stable).
  bool get isProgressing => (change ?? 0) >= 0;

  /// Dette restante toutes catégories confondues.
  double get totalDebt =>
      debts.fold(0, (total, debt) => total + debt.remainingDebt);

  /// `true` tant qu'aucun compte n'a été créé pour cette devise.
  bool get isEmpty => accounts.isEmpty;
}

import 'package:juka/common/enums/app_currency.dart';

/// Photo mensuelle du patrimoine pour une devise.
///
/// Une devise n'est jamais convertie en une autre : chaque devise dispose donc
/// de ses propres photos (voir `WealthCalculator.snapshot`).
class NetWorthSnapshot {
  const NetWorthSnapshot({
    required this.month,
    required this.currency,
    required this.assets,
    required this.liabilities,
    required this.recordedAt,
  });

  /// Mois photographié (premier jour du mois, à minuit).
  final DateTime month;

  final AppCurrency currency;

  /// Somme des soldes positifs des comptes d'actifs.
  final double assets;

  /// Somme des montants dus (dettes et comptes à découvert), toujours positif.
  final double liabilities;

  /// Date à laquelle la photo a été prise.
  final DateTime recordedAt;

  /// Patrimoine net : actifs − dettes.
  double get netWorth => assets - liabilities;

  /// `true` si la photo ne contient aucun montant (compte créé après coup).
  bool get isEmpty => assets == 0 && liabilities == 0;

  /// La photo concerne-t-elle [date] ?
  bool isSameMonth(DateTime date) =>
      month.year == date.year && month.month == date.month;

  NetWorthSnapshot copyWith({
    DateTime? month,
    AppCurrency? currency,
    double? assets,
    double? liabilities,
    DateTime? recordedAt,
  }) {
    return NetWorthSnapshot(
      month: month ?? this.month,
      currency: currency ?? this.currency,
      assets: assets ?? this.assets,
      liabilities: liabilities ?? this.liabilities,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }
}

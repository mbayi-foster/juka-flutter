/// Devises supportées par l'application.
///
/// Chaque devise porte son symbole et son nombre de décimales, ce qui permet
/// de formater correctement les montants (le franc CFA s'écrit sans décimales).
enum AppCurrency {
  eur(code: 'EUR', symbol: '€', label: 'Euro', decimalDigits: 2),
  usd(code: 'USD', symbol: r'$', label: 'Dollar américain', decimalDigits: 2),
  gbp(code: 'GBP', symbol: '£', label: 'Livre sterling', decimalDigits: 2),
  chf(code: 'CHF', symbol: 'CHF', label: 'Franc suisse', decimalDigits: 2),
  cad(code: 'CAD', symbol: r'$ CA', label: 'Dollar canadien', decimalDigits: 2),
  mad(code: 'MAD', symbol: 'DH', label: 'Dirham marocain', decimalDigits: 2),
  xof(
    code: 'XOF',
    symbol: 'F CFA',
    label: 'Franc CFA (UEMOA)',
    decimalDigits: 0,
  ),
  xaf(
    code: 'XAF',
    symbol: 'F CFA',
    label: 'Franc CFA (CEMAC)',
    decimalDigits: 0,
  ),
  ngn(code: 'NGN', symbol: '₦', label: 'Naira nigérian', decimalDigits: 2),
  cdf(code: 'CDF', symbol: 'FC', label: 'Franc congolais', decimalDigits: 2);

  const AppCurrency({
    required this.code,
    required this.symbol,
    required this.label,
    required this.decimalDigits,
  });

  /// Code ISO 4217 (`EUR`, `XOF`…).
  final String code;

  /// Symbole affiché après le montant (`€`, `F CFA`…).
  final String symbol;

  /// Nom lisible de la devise.
  final String label;

  /// Nombre de décimales à afficher pour cette devise.
  final int decimalDigits;

  /// Libellé complet utilisé dans les listes de choix : `EUR — Euro`.
  String get displayName => '$code — $label';
}

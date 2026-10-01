/// Erreur technique de la couche `data` des rapports.
///
/// Traduite en `ReportsFailure` avant de remonter au domaine.
class ReportsException implements Exception {
  const ReportsException(this.message);

  final String message;

  @override
  String toString() => 'ReportsException: $message';
}

/// Niveau d'importance d'une alerte du tableau de bord.
enum AlertSeverity { info, success, warning, danger }

/// Alerte affichée à l'utilisateur (budget dépassé, échéance à venir…).
class DashboardAlert {
  const DashboardAlert({
    required this.title,
    required this.message,
    this.severity = AlertSeverity.info,
  });

  final String title;
  final String message;
  final AlertSeverity severity;
}

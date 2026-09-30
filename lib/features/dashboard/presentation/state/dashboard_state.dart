import 'package:juka/features/dashboard/domain/entities/dashboard_overview.dart';

/// État du tableau de bord : chargement, données ou erreur.
enum DashboardStatus { loading, ready, failure }

/// État exposé par `dashboardControllerProvider`.
class DashboardState {
  const DashboardState({
    this.status = DashboardStatus.loading,
    this.overview,
    this.errorMessage,
  });

  final DashboardStatus status;

  /// Données affichées, `null` tant qu'aucun chargement n'a abouti.
  final DashboardOverview? overview;

  /// Message d'erreur affichable, `null` si tout va bien.
  final String? errorMessage;

  bool get isLoading => status == DashboardStatus.loading;

  bool get hasFailed => status == DashboardStatus.failure;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardOverview? overview,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

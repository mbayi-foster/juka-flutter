import 'package:juka/features/dashboard/domain/entities/dashboard_overview.dart';
import 'package:juka/features/dashboard/domain/repositories/dashboard_repository.dart';

/// Récupère l'agrégat complet affiché par le tableau de bord.
class GetDashboardOverviewUseCase {
  const GetDashboardOverviewUseCase(this._repository);

  final DashboardRepository _repository;

  Future<DashboardOverview> call() => _repository.fetchOverview();
}

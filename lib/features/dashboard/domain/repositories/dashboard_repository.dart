import 'package:juka/features/dashboard/domain/entities/dashboard_overview.dart';

/// Contrat du domaine pour la récupération des données du tableau de bord.
///
/// L'implémentation concrète vit dans la couche `data` : le domaine ignore si
/// les données proviennent de l'API, d'un cache local ou d'une simulation.
abstract interface class DashboardRepository {
  Future<DashboardOverview> fetchOverview();
}

import 'package:juka/features/dashboard/data/datasources/dashboard_local_data_source.dart';
import 'package:juka/features/dashboard/domain/entities/dashboard_overview.dart';
import 'package:juka/features/dashboard/domain/failures/dashboard_failure.dart';
import 'package:juka/features/dashboard/domain/repositories/dashboard_repository.dart';

/// Implémentation du contrat [DashboardRepository] au-dessus de la source
/// locale, en attendant les endpoints de `api-juka`.
///
/// Elle traduit les erreurs techniques en [DashboardFailure] métier.
class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._localDataSource);

  final DashboardLocalDataSource _localDataSource;

  static const String _unexpectedMessage =
      'Impossible de charger votre tableau de bord. Veuillez réessayer.';

  @override
  Future<DashboardOverview> fetchOverview() async {
    try {
      return await _localDataSource.fetchOverview();
    } on DashboardFailure {
      rethrow;
    } catch (_) {
      throw const DashboardFailure(_unexpectedMessage);
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/features/dashboard/data/datasources/dashboard_local_data_source.dart';
import 'package:juka/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:juka/features/dashboard/domain/failures/dashboard_failure.dart';
import 'package:juka/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:juka/features/dashboard/domain/usecases/get_dashboard_overview_usecase.dart';
import 'package:juka/features/dashboard/presentation/state/dashboard_state.dart';

// ---------------------------------------------------------------------------
// Injection des dépendances (data -> domain)
// ---------------------------------------------------------------------------

final dashboardLocalDataSourceProvider = Provider<DashboardLocalDataSource>(
  (ref) => const DashboardLocalDataSourceImpl(),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(ref.watch(dashboardLocalDataSourceProvider)),
);

final getDashboardOverviewUseCaseProvider =
    Provider<GetDashboardOverviewUseCase>(
      (ref) =>
          GetDashboardOverviewUseCase(ref.watch(dashboardRepositoryProvider)),
    );

// ---------------------------------------------------------------------------
// Contrôleur
// ---------------------------------------------------------------------------

/// Charge et expose les données du tableau de bord.
final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(
      DashboardController.new,
    );

class DashboardController extends Notifier<DashboardState> {
  static const String _unexpectedMessage =
      'Une erreur inattendue est survenue. Veuillez réessayer.';

  @override
  DashboardState build() => const DashboardState();

  /// (Re)charge l'agrégat ; les données déjà affichées restent visibles pendant
  /// le rafraîchissement.
  Future<void> load() async {
    state = DashboardState(
      status: DashboardStatus.loading,
      overview: state.overview,
    );

    try {
      final overview = await ref.read(getDashboardOverviewUseCaseProvider)();
      state = DashboardState(status: DashboardStatus.ready, overview: overview);
    } on DashboardFailure catch (failure) {
      state = DashboardState(
        status: DashboardStatus.failure,
        overview: state.overview,
        errorMessage: failure.message,
      );
    } catch (_) {
      state = DashboardState(
        status: DashboardStatus.failure,
        overview: state.overview,
        errorMessage: _unexpectedMessage,
      );
    }
  }
}

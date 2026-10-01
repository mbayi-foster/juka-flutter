import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:juka/features/categories/presentation/providers/categories_providers.dart';
import 'package:juka/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:juka/features/dashboard/domain/failures/dashboard_failure.dart';
import 'package:juka/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:juka/features/dashboard/domain/usecases/get_dashboard_overview_usecase.dart';
import 'package:juka/features/dashboard/presentation/state/dashboard_state.dart';
import 'package:juka/features/operations/presentation/providers/operations_providers.dart';
import 'package:juka/features/wealth/presentation/providers/wealth_providers.dart';

// ---------------------------------------------------------------------------
// Injection des dépendances (data -> domain)
// ---------------------------------------------------------------------------

/// Le tableau de bord agrège les données des autres modules (comptes,
/// opérations, catégories, patrimoine) : il n'a pas de stockage propre.
///
/// Les tests remplacent ce provider pour fournir un jeu de données fixe.
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(
    accountsRepository: ref.watch(accountsRepositoryProvider),
    operationsRepository: ref.watch(operationsRepositoryProvider),
    categoriesRepository: ref.watch(categoriesRepositoryProvider),
    wealthRepository: ref.watch(wealthRepositoryProvider),
  ),
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

    // Photo mensuelle automatique du patrimoine : elle est rafraîchie à chaque
    // ouverture de l'application (le tableau de bord est l'écran d'accueil).
    // Un échec ici ne doit pas empêcher le tableau de bord de s'afficher.
    try {
      await ref.read(refreshNetWorthSnapshotUseCaseProvider)();
    } catch (_) {
      // Ignoré : la photo sera retentée au prochain chargement.
    }

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

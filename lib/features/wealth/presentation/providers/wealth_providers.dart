import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:juka/features/operations/presentation/providers/operations_providers.dart';
import 'package:juka/features/wealth/data/datasources/wealth_sqflite_data_source.dart';
import 'package:juka/features/wealth/data/repositories/wealth_repository_impl.dart';
import 'package:juka/features/wealth/domain/entities/net_worth_snapshot.dart';
import 'package:juka/features/wealth/domain/failures/wealth_failure.dart';
import 'package:juka/features/wealth/domain/repositories/wealth_repository.dart';
import 'package:juka/features/wealth/domain/usecases/wealth_usecases.dart';
import 'package:juka/features/wealth/presentation/state/wealth_state.dart';
import 'package:juka/shared/database/app_database.dart';

// ---------------------------------------------------------------------------
// Injection des dépendances (data -> domain)
// ---------------------------------------------------------------------------

/// Source locale du patrimoine : photos mensuelles en SQLite.
final wealthLocalDataSourceProvider = Provider<WealthRepository>(
  (ref) => WealthSqfliteDataSource(ref.watch(appDatabaseProvider)),
);

final wealthRepositoryProvider = Provider<WealthRepository>(
  (ref) => WealthRepositoryImpl(ref.watch(wealthLocalDataSourceProvider)),
);

/// Enregistre la photo du mois : appelé à l'ouverture pour que le suivi
/// mensuel soit automatique.
final refreshNetWorthSnapshotUseCaseProvider =
    Provider<RefreshNetWorthSnapshotUseCase>(
      (ref) => RefreshNetWorthSnapshotUseCase(
        ref.watch(wealthRepositoryProvider),
        ref.watch(accountsRepositoryProvider),
      ),
    );

final getWealthOverviewUseCaseProvider = Provider<GetWealthOverviewUseCase>(
  (ref) => GetWealthOverviewUseCase(
    ref.watch(wealthRepositoryProvider),
    ref.watch(accountsRepositoryProvider),
    ref.watch(operationsRepositoryProvider),
  ),
);

/// Photo du mois précédent pour une devise, utilisée par le tableau de bord
/// pour calculer l'évolution du patrimoine.
final previousNetWorthSnapshotProvider =
    FutureProvider.family<NetWorthSnapshot?, AppCurrency>((ref, currency) {
      return ref
          .watch(wealthRepositoryProvider)
          .fetchSnapshots(currency: currency, limit: 2)
          .then((snapshots) {
            final now = DateTime.now();
            final target = DateTime(now.year, now.month - 1);
            for (final snapshot in snapshots) {
              if (snapshot.isSameMonth(target)) return snapshot;
            }
            return null;
          });
    });

// ---------------------------------------------------------------------------
// Contrôleur
// ---------------------------------------------------------------------------

/// Calcule le patrimoine et son évolution pour la devise affichée.
final wealthControllerProvider =
    NotifierProvider<WealthController, WealthState>(WealthController.new);

class WealthController extends Notifier<WealthState> {
  static const String _unexpectedMessage =
      'Une erreur inattendue est survenue. Veuillez réessayer.';

  @override
  WealthState build() => const WealthState();

  /// Recalcule le patrimoine (et enregistre la photo du mois).
  Future<void> load({AppCurrency? currency}) async {
    state = WealthState(
      status: WealthStatus.loading,
      overview: state.overview,
      currency: currency ?? state.currency,
    );
    await _reload();
  }

  /// Change la devise affichée (les devises ne sont pas converties).
  Future<void> selectCurrency(AppCurrency currency) => load(currency: currency);

  Future<void> _reload() async {
    try {
      final overview = await ref.read(getWealthOverviewUseCaseProvider)(
        currency: state.currency,
      );

      state = overview == null
          ? WealthState(status: WealthStatus.empty, currency: state.currency)
          : WealthState(
              status: WealthStatus.ready,
              overview: overview,
              currency: overview.currency,
            );
    } on WealthFailure catch (failure) {
      state = WealthState(
        status: WealthStatus.failure,
        overview: state.overview,
        currency: state.currency,
        errorMessage: failure.message,
      );
    } catch (_) {
      state = WealthState(
        status: WealthStatus.failure,
        overview: state.overview,
        currency: state.currency,
        errorMessage: _unexpectedMessage,
      );
    }
  }
}

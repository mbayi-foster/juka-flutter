import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/common/enums/account_type.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/data/datasources/accounts_local_data_source.dart';
import 'package:juka/features/accounts/data/repositories/accounts_repository_impl.dart';
import 'package:juka/features/accounts/domain/entities/account_balance_point.dart';
import 'package:juka/features/accounts/domain/failures/accounts_failure.dart';
import 'package:juka/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:juka/features/accounts/domain/usecases/create_account_usecase.dart';
import 'package:juka/features/accounts/domain/usecases/get_account_balance_history_usecase.dart';
import 'package:juka/features/accounts/domain/usecases/get_accounts_usecase.dart';
import 'package:juka/features/accounts/domain/usecases/reconcile_account_usecase.dart';
import 'package:juka/features/accounts/domain/usecases/set_account_archived_usecase.dart';
import 'package:juka/features/accounts/domain/usecases/update_account_usecase.dart';
import 'package:juka/features/accounts/presentation/state/accounts_state.dart';

// ---------------------------------------------------------------------------
// Injection des dépendances (data -> domain)
// ---------------------------------------------------------------------------

final accountsLocalDataSourceProvider = Provider<AccountsLocalDataSource>(
  (ref) => AccountsLocalDataSourceImpl(),
);

final accountsRepositoryProvider = Provider<AccountsRepository>(
  (ref) => AccountsRepositoryImpl(ref.watch(accountsLocalDataSourceProvider)),
);

final getAccountsUseCaseProvider = Provider<GetAccountsUseCase>(
  (ref) => GetAccountsUseCase(ref.watch(accountsRepositoryProvider)),
);

final getAccountBalanceHistoryUseCaseProvider =
    Provider<GetAccountBalanceHistoryUseCase>(
      (ref) => GetAccountBalanceHistoryUseCase(
        ref.watch(accountsRepositoryProvider),
      ),
    );

final createAccountUseCaseProvider = Provider<CreateAccountUseCase>(
  (ref) => CreateAccountUseCase(ref.watch(accountsRepositoryProvider)),
);

final updateAccountUseCaseProvider = Provider<UpdateAccountUseCase>(
  (ref) => UpdateAccountUseCase(ref.watch(accountsRepositoryProvider)),
);

final setAccountArchivedUseCaseProvider = Provider<SetAccountArchivedUseCase>(
  (ref) => SetAccountArchivedUseCase(ref.watch(accountsRepositoryProvider)),
);

final reconcileAccountUseCaseProvider = Provider<ReconcileAccountUseCase>(
  (ref) => ReconcileAccountUseCase(ref.watch(accountsRepositoryProvider)),
);

/// Historique de solde d'un compte, chargé à la demande par la page de détail.
final accountBalanceHistoryProvider =
    FutureProvider.family<List<AccountBalancePoint>, String>((ref, accountId) {
      return ref.watch(getAccountBalanceHistoryUseCaseProvider)(accountId);
    });

// ---------------------------------------------------------------------------
// Contrôleur
// ---------------------------------------------------------------------------

/// Pilote les cas d'usage des comptes et expose l'état aux écrans.
final accountsControllerProvider =
    NotifierProvider<AccountsController, AccountsState>(AccountsController.new);

class AccountsController extends Notifier<AccountsState> {
  static const String _unexpectedMessage =
      'Une erreur inattendue est survenue. Veuillez réessayer.';

  @override
  AccountsState build() => const AccountsState();

  /// Charge les comptes (premier affichage ou tirer-pour-rafraîchir).
  Future<void> load() async {
    state = AccountsState(
      status: AccountsStatus.loading,
      accounts: state.accounts,
    );
    await _reload();
  }

  /// Crée un compte. Retourne `null` en cas de succès, sinon le message
  /// d'erreur à afficher.
  Future<String?> create({
    required String name,
    required AccountType type,
    required AppCurrency currency,
    required double initialBalance,
    String? note,
  }) {
    return _mutate(
      () => ref.read(createAccountUseCaseProvider)(
        name: name,
        type: type,
        currency: currency,
        initialBalance: initialBalance,
        note: note,
      ),
    );
  }

  /// Modifie un compte existant.
  Future<String?> update({
    required String id,
    required String name,
    required AccountType type,
    required AppCurrency currency,
    required double initialBalance,
    String? note,
  }) {
    return _mutate(
      () => ref.read(updateAccountUseCaseProvider)(
        id: id,
        name: name,
        type: type,
        currency: currency,
        initialBalance: initialBalance,
        note: note,
      ),
    );
  }

  /// Archive ou restaure un compte.
  Future<String?> setArchived({required String id, required bool isArchived}) {
    return _mutate(
      () => ref.read(setAccountArchivedUseCaseProvider)(
        id: id,
        isArchived: isArchived,
      ),
    );
  }

  /// Enregistre le solde réel constaté pour le rapprochement.
  Future<String?> reconcile({required String id, required double realBalance}) {
    return _mutate(
      () => ref.read(reconcileAccountUseCaseProvider)(
        id: id,
        realBalance: realBalance,
      ),
    );
  }

  /// Exécute une mutation puis recharge la liste. Retourne le message d'erreur
  /// à afficher, ou `null` en cas de succès.
  Future<String?> _mutate(Future<Object?> Function() action) async {
    try {
      await action();
      await _reload();
      return null;
    } on AccountsFailure catch (failure) {
      return failure.message;
    } catch (_) {
      return _unexpectedMessage;
    }
  }

  /// Recharge la liste sans repasser par l'état de chargement, pour éviter un
  /// clignotement après une création ou une modification.
  Future<void> _reload() async {
    try {
      final accounts = await ref.read(getAccountsUseCaseProvider)();
      state = AccountsState(status: AccountsStatus.ready, accounts: accounts);
    } on AccountsFailure catch (failure) {
      state = _failure(failure.message);
    } catch (_) {
      state = _failure(_unexpectedMessage);
    }
  }

  AccountsState _failure(String message) => AccountsState(
    status: AccountsStatus.failure,
    accounts: state.accounts,
    errorMessage: message,
  );
}

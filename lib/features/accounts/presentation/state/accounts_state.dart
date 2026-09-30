import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';

/// État de la liste des comptes : chargement, données ou erreur.
enum AccountsStatus { loading, ready, failure }

/// État exposé par `accountsControllerProvider`.
class AccountsState {
  const AccountsState({
    this.status = AccountsStatus.loading,
    this.accounts = const [],
    this.errorMessage,
  });

  final AccountsStatus status;

  /// Tous les comptes, archivés compris.
  final List<Account> accounts;

  /// Message d'erreur affichable, `null` si tout va bien.
  final String? errorMessage;

  bool get isLoading => status == AccountsStatus.loading;

  bool get hasFailed => status == AccountsStatus.failure;

  /// Comptes visibles dans la liste principale.
  List<Account> get activeAccounts =>
      accounts.where((account) => !account.isArchived).toList();

  /// Comptes conservés mais sortis des totaux.
  List<Account> get archivedAccounts =>
      accounts.where((account) => account.isArchived).toList();

  /// Soldes cumulés par devise.
  ///
  /// Les devises ne sont jamais additionnées entre elles : on obtient un total
  /// par devise présente dans les comptes actifs.
  Map<AppCurrency, double> get totalsByCurrency {
    final totals = <AppCurrency, double>{};
    for (final account in activeAccounts) {
      totals.update(
        account.currency,
        (total) => total + account.currentBalance,
        ifAbsent: () => account.currentBalance,
      );
    }
    return totals;
  }

  Account? accountById(String id) {
    for (final account in accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  AccountsState copyWith({
    AccountsStatus? status,
    List<Account>? accounts,
    String? errorMessage,
  }) {
    return AccountsState(
      status: status ?? this.status,
      accounts: accounts ?? this.accounts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

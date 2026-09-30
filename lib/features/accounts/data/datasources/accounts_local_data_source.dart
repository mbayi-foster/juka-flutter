import 'package:juka/common/enums/account_type.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/data/datasources/balance_history_builder.dart';
import 'package:juka/features/accounts/data/exceptions/accounts_exception.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/accounts/domain/entities/account_balance_point.dart';

/// Source de données des comptes.
abstract interface class AccountsLocalDataSource {
  Future<List<Account>> fetchAccounts();

  Future<List<AccountBalancePoint>> fetchBalanceHistory(String accountId);

  Future<Account> createAccount({
    required String name,
    required AccountType type,
    required AppCurrency currency,
    required double initialBalance,
    String? note,
  });

  Future<Account> updateAccount({
    required String id,
    required String name,
    required AccountType type,
    required AppCurrency currency,
    required double initialBalance,
    String? note,
  });

  Future<Account> setArchived({required String id, required bool isArchived});

  Future<Account> reconcile({required String id, required double realBalance});
}

/// Implémentation en mémoire, pré-remplie de comptes de démonstration.
///
/// Utilisée par les tests et les démonstrations, où `sqflite` n'est pas
/// disponible. En production, c'est `AccountsSqfliteDataSource` qui est
/// injectée : les deux respectent le même contrat [AccountsLocalDataSource].
class AccountsLocalDataSourceImpl implements AccountsLocalDataSource {
  AccountsLocalDataSourceImpl() {
    _seed();
  }

  /// Latence simulée pour rendre les états de chargement visibles.
  static const Duration _latency = Duration(milliseconds: 250);

  final List<Account> _accounts = [];

  /// Compteur utilisé pour générer les identifiants.
  int _idCounter = 0;

  @override
  Future<List<Account>> fetchAccounts() async {
    await Future<void>.delayed(_latency);
    return List.of(_accounts);
  }

  @override
  Future<List<AccountBalancePoint>> fetchBalanceHistory(
    String accountId,
  ) async {
    await Future<void>.delayed(_latency);
    return BalanceHistoryBuilder.build(_accounts[_indexOf(accountId)]);
  }

  @override
  Future<Account> createAccount({
    required String name,
    required AccountType type,
    required AppCurrency currency,
    required double initialBalance,
    String? note,
  }) async {
    await Future<void>.delayed(_latency);

    final account = Account(
      id: _nextId(),
      name: name,
      type: type,
      currency: currency,
      initialBalance: initialBalance,
      // Un compte neuf démarre au solde saisi.
      currentBalance: initialBalance,
      createdAt: DateTime.now(),
      note: _normalizeNote(note),
    );
    _accounts.add(account);
    return account;
  }

  @override
  Future<Account> updateAccount({
    required String id,
    required String name,
    required AccountType type,
    required AppCurrency currency,
    required double initialBalance,
    String? note,
  }) async {
    await Future<void>.delayed(_latency);

    final index = _indexOf(id);
    final previous = _accounts[index];

    // Le mouvement déjà enregistré est conservé : le solde courant se décale
    // d'autant que le solde initial.
    final updated = Account(
      id: previous.id,
      name: name,
      type: type,
      currency: currency,
      initialBalance: initialBalance,
      currentBalance: initialBalance + previous.movement,
      createdAt: previous.createdAt,
      isArchived: previous.isArchived,
      reconciledBalance: previous.reconciledBalance,
      reconciledAt: previous.reconciledAt,
      note: _normalizeNote(note),
    );

    _accounts[index] = updated;
    return updated;
  }

  @override
  Future<Account> setArchived({
    required String id,
    required bool isArchived,
  }) async {
    await Future<void>.delayed(_latency);

    final index = _indexOf(id);
    final updated = _accounts[index].copyWith(isArchived: isArchived);
    _accounts[index] = updated;
    return updated;
  }

  @override
  Future<Account> reconcile({
    required String id,
    required double realBalance,
  }) async {
    await Future<void>.delayed(_latency);

    final index = _indexOf(id);
    final updated = _accounts[index].copyWith(
      reconciledBalance: realBalance,
      reconciledAt: DateTime.now(),
    );
    _accounts[index] = updated;
    return updated;
  }

  int _indexOf(String id) {
    final index = _accounts.indexWhere((account) => account.id == id);
    if (index == -1) {
      throw const AccountsException('Ce compte est introuvable.');
    }
    return index;
  }

  String _nextId() => 'acc-${++_idCounter}';

  String? _normalizeNote(String? note) {
    final trimmed = note?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  void _seed() {
    final now = DateTime.now();

    _accounts.addAll([
      Account(
        id: _nextId(),
        name: 'Compte courant',
        type: AccountType.bank,
        currency: AppCurrency.eur,
        initialBalance: 1200,
        currentBalance: 3450.80,
        createdAt: now.subtract(const Duration(days: 420)),
      ),
      Account(
        id: _nextId(),
        name: 'Livret A',
        type: AccountType.savings,
        currency: AppCurrency.eur,
        initialBalance: 8000,
        currentBalance: 9850.50,
        createdAt: now.subtract(const Duration(days: 640)),
      ),
      Account(
        id: _nextId(),
        name: 'Orange Money',
        type: AccountType.mobileMoney,
        currency: AppCurrency.xof,
        initialBalance: 50000,
        currentBalance: 128500,
        createdAt: now.subtract(const Duration(days: 210)),
      ),
      Account(
        id: _nextId(),
        name: 'Espèces',
        type: AccountType.cash,
        currency: AppCurrency.eur,
        initialBalance: 80,
        currentBalance: 145.30,
        createdAt: now.subtract(const Duration(days: 90)),
        // Rapproché il y a 3 jours : un écart de 5,30 € reste à expliquer.
        reconciledBalance: 140,
        reconciledAt: now.subtract(const Duration(days: 3)),
      ),
      Account(
        id: _nextId(),
        name: 'Carte de crédit',
        type: AccountType.debt,
        currency: AppCurrency.eur,
        initialBalance: -1200,
        currentBalance: -640,
        createdAt: now.subtract(const Duration(days: 150)),
        note: 'Solde négatif : montant encore dû.',
      ),
      Account(
        id: _nextId(),
        name: 'Prêt à Léa',
        type: AccountType.receivable,
        currency: AppCurrency.eur,
        initialBalance: 500,
        currentBalance: 300,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      Account(
        id: _nextId(),
        name: 'Ancien compte',
        type: AccountType.bank,
        currency: AppCurrency.eur,
        initialBalance: 0,
        currentBalance: 0,
        createdAt: now.subtract(const Duration(days: 900)),
        isArchived: true,
      ),
    ]);
  }
}

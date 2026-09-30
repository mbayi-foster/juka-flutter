import 'package:juka/common/enums/account_type.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/accounts/domain/entities/account_balance_point.dart';

/// Contrat du domaine pour la gestion des comptes.
///
/// L'implémentation concrète vit dans la couche `data` : le domaine ignore si
/// les comptes sont stockés en base locale, en mémoire ou côté API.
abstract interface class AccountsRepository {
  /// Tous les comptes, archivés compris.
  Future<List<Account>> fetchAccounts();

  /// Historique du solde d'un compte, du plus ancien au plus récent.
  Future<List<AccountBalancePoint>> fetchBalanceHistory(String accountId);

  Future<Account> createAccount({
    required String name,
    required AccountType type,
    required AppCurrency currency,
    required double initialBalance,
    String? note,
  });

  /// Met à jour un compte. Le mouvement déjà enregistré est conservé : le
  /// solde courant est décalé de la différence sur le solde initial.
  Future<Account> updateAccount({
    required String id,
    required String name,
    required AccountType type,
    required AppCurrency currency,
    required double initialBalance,
    String? note,
  });

  /// Archive ou restaure un compte.
  Future<Account> setArchived({required String id, required bool isArchived});

  /// Enregistre le solde réel constaté pour le rapprochement.
  Future<Account> reconcile({required String id, required double realBalance});
}

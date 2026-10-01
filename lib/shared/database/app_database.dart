import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/common/constants/app_constants.dart';
import 'package:sqflite/sqflite.dart';

/// Base SQLite locale de l'application.
///
/// Toutes les tables vivent dans le même fichier et sont déclarées ici : les
/// modules (comptes, opérations…) partagent ainsi une connexion unique, ce qui
/// évite les conflits d'ouverture et permet des écritures transactionnelles
/// touchant plusieurs tables (par exemple une opération qui met à jour le solde
/// d'un compte).
class AppDatabase {
  AppDatabase();

  /// Version du schéma : à incrémenter à chaque évolution des tables.
  ///
  /// v1 : table `accounts` seule.
  /// v2 : ajout de `operations`, `recurring_operations` et
  ///      `operation_attachments`.
  /// v3 : ajout de `categories`, `budgets` et `app_settings` (catégories
  ///      personnalisables, budgets mensuels, préférences d'affichage).
  /// v4 : ajout de `net_worth_snapshots` (photos mensuelles du patrimoine).
  static const int schemaVersion = 4;

  Future<Database>? _database;

  /// Connexion à la base, ouverte au premier accès puis réutilisée.
  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    // `package:path` n'est pas une dépendance directe du projet : le chemin est
    // construit à partir du répertoire fourni par `sqflite`.
    final path = '${await getDatabasesPath()}/${AppConstants.dbName}';

    return openDatabase(
      path,
      version: schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) => _createSchema(db);

  /// Migration du schéma.
  ///
  /// Les instructions sont idempotentes (`IF NOT EXISTS`) : les rejouer ajoute
  /// les tables manquantes sans toucher aux données déjà enregistrées. Une base
  /// créée avant l'arrivée du module Opérations passe donc de « accounts » seule
  /// au schéma complet, ce qui évite les erreurs « no such table: operations ».
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) =>
      _createSchema(db);

  Future<void> _createSchema(Database db) async {
    for (final statement in _createStatements) {
      await db.execute(statement);
    }
  }

  /// Schéma complet de l'application, exécuté à la création de la base.
  static const List<String> _createStatements = [
    '''
    CREATE TABLE IF NOT EXISTS accounts (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      currency TEXT NOT NULL,
      initial_balance REAL NOT NULL,
      current_balance REAL NOT NULL,
      created_at INTEGER NOT NULL,
      is_archived INTEGER NOT NULL DEFAULT 0,
      reconciled_balance REAL,
      reconciled_at INTEGER,
      note TEXT
    )
    ''',
    '''
    CREATE TABLE IF NOT EXISTS operations (
      id TEXT PRIMARY KEY,
      label TEXT NOT NULL,
      type TEXT NOT NULL,
      amount REAL NOT NULL,
      category TEXT NOT NULL,
      account_id TEXT NOT NULL,
      transfer_account_id TEXT,
      date INTEGER NOT NULL,
      note TEXT,
      recurring_operation_id TEXT
    )
    ''',
    'CREATE INDEX IF NOT EXISTS idx_operations_date ON operations (date DESC)',
    '''
    CREATE TABLE IF NOT EXISTS recurring_operations (
      id TEXT PRIMARY KEY,
      label TEXT NOT NULL,
      type TEXT NOT NULL,
      amount REAL NOT NULL,
      category TEXT NOT NULL,
      account_id TEXT NOT NULL,
      transfer_account_id TEXT,
      frequency TEXT NOT NULL,
      next_occurrence INTEGER NOT NULL,
      note TEXT,
      is_active INTEGER NOT NULL DEFAULT 1,
      last_generated_at INTEGER
    )
    ''',
    '''
    CREATE TABLE IF NOT EXISTS operation_attachments (
      id TEXT PRIMARY KEY,
      operation_id TEXT NOT NULL,
      file_path TEXT NOT NULL,
      file_name TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      mime_type TEXT,
      size_in_bytes INTEGER
    )
    ''',
    '''
    CREATE TABLE IF NOT EXISTS categories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      kind TEXT NOT NULL,
      parent_id TEXT,
      icon_key TEXT NOT NULL,
      color_hex INTEGER NOT NULL,
      is_archived INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL
    )
    ''',
    '''
    CREATE TABLE IF NOT EXISTS budgets (
      category_id TEXT PRIMARY KEY,
      monthly_limit REAL NOT NULL,
      carry_over INTEGER NOT NULL DEFAULT 0,
      updated_at INTEGER NOT NULL
    )
    ''',
    '''
    CREATE TABLE IF NOT EXISTS app_settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE IF NOT EXISTS net_worth_snapshots (
      month INTEGER NOT NULL,
      currency TEXT NOT NULL,
      assets REAL NOT NULL,
      liabilities REAL NOT NULL,
      recorded_at INTEGER NOT NULL,
      PRIMARY KEY (month, currency)
    )
    ''',
  ];
}

/// Connexion partagée par toutes les sources de données locales.
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

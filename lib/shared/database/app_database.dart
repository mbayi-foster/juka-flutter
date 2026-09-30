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
  static const int schemaVersion = 1;

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

  Future<void> _onCreate(Database db, int version) async {
    for (final statement in _createStatements) {
      await db.execute(statement);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Première version du schéma : aucune migration à jouer pour l'instant.
  }

  /// Schéma complet de l'application, exécuté à la création de la base.
  static const List<String> _createStatements = [
    '''
    CREATE TABLE accounts (
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
    CREATE TABLE operations (
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
    'CREATE INDEX idx_operations_date ON operations (date DESC)',
    '''
    CREATE TABLE recurring_operations (
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
    CREATE TABLE operation_attachments (
      id TEXT PRIMARY KEY,
      operation_id TEXT NOT NULL,
      file_path TEXT NOT NULL,
      file_name TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      mime_type TEXT,
      size_in_bytes INTEGER
    )
    ''',
  ];
}

/// Connexion partagée par toutes les sources de données locales.
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

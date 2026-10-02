import 'dart:convert';

/// Sauvegarde locale : lecture et écriture du fichier JSON.
///
/// Le format est volontairement simple — une entrée par table — pour rester
/// lisible et réparable à la main si besoin.
class BackupCodec {
  /// Marqueur permettant de reconnaître un fichier Juka.
  static const String format = 'juka-backup';

  /// Version du format d'échange.
  static const int version = 1;

  /// Tables sauvegardées, dans l'ordre d'écriture.
  static const List<String> tables = [
    'accounts',
    'operations',
    'operation_attachments',
    'recurring_operations',
    'categories',
    'budgets',
    'net_worth_snapshots',
    'currencies',
    'exchange_rates',
    'app_settings',
  ];

  /// Sérialise [rows] (table → lignes) en JSON indenté.
  static String encode({
    required Map<String, List<Map<String, Object?>>> rows,
    required DateTime createdAt,
  }) {
    return const JsonEncoder.withIndent('  ').convert({
      'format': format,
      'version': version,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'tables': {for (final table in tables) table: rows[table] ?? const []},
    });
  }

  /// Relit un fichier de sauvegarde.
  ///
  /// Lève [BackupFormatException] si le contenu n'est pas une sauvegarde Juka
  /// exploitable : mieux vaut refuser un fichier que restaurer n'importe quoi.
  static BackupDocument decode(String content) {
    final Object? parsed;
    try {
      parsed = jsonDecode(content);
    } catch (_) {
      throw const BackupFormatException(
        'Ce fichier n\'est pas une sauvegarde Juka lisible.',
      );
    }

    if (parsed is! Map<String, Object?>) {
      throw const BackupFormatException(
        'Ce fichier n\'est pas une sauvegarde Juka lisible.',
      );
    }
    if (parsed['format'] != format) {
      throw const BackupFormatException('Ce fichier ne provient pas de Juka.');
    }

    final fileVersion = parsed['version'];
    if (fileVersion is! int || fileVersion > version) {
      throw const BackupFormatException(
        'Cette sauvegarde a été créée par une version plus récente '
        'de l\'application.',
      );
    }

    final rawTables = parsed['tables'];
    if (rawTables is! Map<String, Object?>) {
      throw const BackupFormatException(
        'Cette sauvegarde ne contient aucune donnée.',
      );
    }

    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in BackupCodec.tables) {
      final rawRows = rawTables[table];
      if (rawRows is! List) continue;

      tables[table] = [
        for (final row in rawRows)
          if (row is Map) row.cast<String, Object?>(),
      ];
    }

    final createdAt = parsed['createdAt'];
    return BackupDocument(
      createdAt: createdAt is int
          ? DateTime.fromMillisecondsSinceEpoch(createdAt)
          : DateTime.now(),
      tables: tables,
    );
  }
}

/// Sauvegarde relue : son horodatage et son contenu par table.
class BackupDocument {
  const BackupDocument({required this.createdAt, required this.tables});

  final DateTime createdAt;
  final Map<String, List<Map<String, Object?>>> tables;

  /// Nombre total d'enregistrements sauvegardés.
  int get rowCount =>
      tables.values.fold(0, (total, rows) => total + rows.length);

  /// Nombre d'enregistrements par table.
  Map<String, int> get counts => {
    for (final entry in tables.entries)
      if (entry.value.isNotEmpty) entry.key: entry.value.length,
  };
}

/// Fichier de sauvegarde refusé (format inconnu, version trop récente…).
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

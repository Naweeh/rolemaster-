import 'package:sqlite3/sqlite3.dart';

import 'sqlite_schema.dart';

final class SqliteDatabaseDiagnostic {
  const SqliteDatabaseDiagnostic({
    required this.sqliteVersion,
    required this.schemaVersion,
    required this.integrityMessages,
    required this.foreignKeyFailures,
    required this.roleMasterSchemaPresent,
  });

  final String sqliteVersion;
  final int schemaVersion;
  final List<String> integrityMessages;
  final List<String> foreignKeyFailures;
  final bool roleMasterSchemaPresent;

  bool get isHealthy =>
      roleMasterSchemaPresent &&
      integrityMessages.length == 1 &&
      integrityMessages.single == 'ok' &&
      foreignKeyFailures.isEmpty &&
      schemaVersion > 0 &&
      schemaVersion <= rolemasterSqliteSchemaVersion;
}

final class SqliteDatabaseDiagnostics {
  const SqliteDatabaseDiagnostics();

  /// Opens the database read-only and reports health without running migrations.
  SqliteDatabaseDiagnostic inspect(String path) {
    final database = sqlite3.open(path, mode: OpenMode.readOnly);
    try {
      final integrity = database
          .select('PRAGMA integrity_check')
          .map((row) => row['integrity_check'] as String)
          .toList(growable: false);
      final foreignKeys = database.select('PRAGMA foreign_key_check');
      final failures = foreignKeys
          .map(
            (row) =>
                '${row['table']} rowid=${row['rowid']} parent=${row['parent']}',
          )
          .toList(growable: false);
      final tables = database.select(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      return SqliteDatabaseDiagnostic(
        sqliteVersion: sqlite3.version.toString(),
        schemaVersion: database.userVersion,
        integrityMessages: List<String>.unmodifiable(integrity),
        foreignKeyFailures: List<String>.unmodifiable(failures),
        roleMasterSchemaPresent: tables.any(
          (row) => row['name'] == 'campaigns',
        ),
      );
    } finally {
      database.close();
    }
  }
}

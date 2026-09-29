import 'dart:convert';
import 'dart:developer' as developer;

import 'package:sqlite3/sqlite3.dart';

/// Structured operational logs. Callers should never put prompts or campaign
/// content in fields.
abstract interface class SqliteOperationLogger {
  void record(String event, Map<String, Object?> fields);
}

final class DeveloperSqliteOperationLogger implements SqliteOperationLogger {
  const DeveloperSqliteOperationLogger();

  @override
  void record(String event, Map<String, Object?> fields) {
    developer.log('$event ${jsonEncode(fields)}', name: 'rolemaster.sqlite');
  }
}

final Expando<bool> _observedDatabases = Expando<bool>(
  'rolemaster.sqlite.operation-observer',
);
final Expando<SqliteOperationLogger> _databaseLoggers =
    Expando<SqliteOperationLogger>('rolemaster.sqlite.logger');

/// Logs only the operation kind and exception type. Query text, parameters,
/// values, paths, and exception messages must stay out of operational logs.
extension LoggedSqliteRepositoryOperations on Database {
  ResultSet loggedSelect(String sql, [List<Object?> parameters = const []]) {
    try {
      return select(sql, parameters);
    } catch (error) {
      _recordFailure(this, 'read', error);
      rethrow;
    }
  }

  void loggedExecute(String sql, [List<Object?> parameters = const []]) {
    try {
      execute(sql, parameters);
    } catch (error) {
      _recordFailure(this, 'write', error);
      rethrow;
    }
  }
}

void _recordFailure(Database database, String operation, Object error) {
  try {
    (_databaseLoggers[database] ?? const DeveloperSqliteOperationLogger())
        .record('sqlite.repository.operation.failed', <String, Object?>{
          'operation': operation,
          'errorType': error.runtimeType.toString(),
        });
  } catch (_) {
    // Logging must never replace the database error.
  }
}

/// Records committed row changes and rolled-back writes without row IDs,
/// query text, parameters, or campaign content.
void observeSqliteDatabaseOperations(
  Database database,
  SqliteOperationLogger logger,
) {
  _databaseLoggers[database] = logger;
  if (_observedDatabases[database] == true) {
    return;
  }
  _observedDatabases[database] = true;

  final pendingChanges = <String, int>{};

  void recordChanges(String event) {
    if (pendingChanges.isEmpty) {
      return;
    }
    final changes = Map<String, int>.unmodifiable(pendingChanges);
    pendingChanges.clear();
    try {
      logger.record(event, <String, Object?>{'changes': changes});
    } catch (_) {
      // Logging must not change the outcome of a database operation.
    }
  }

  database.updatesSync.listen((update) {
    final key = '${update.tableName}.${update.kind.name}';
    pendingChanges.update(key, (count) => count + 1, ifAbsent: () => 1);
  });
  database.commits.listen((_) => recordChanges('sqlite.transaction.committed'));
  database.rollbacks.listen(
    (_) => recordChanges('sqlite.transaction.rolled_back'),
  );
}

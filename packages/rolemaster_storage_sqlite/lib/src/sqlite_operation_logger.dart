import 'dart:convert';
import 'dart:developer' as developer;

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

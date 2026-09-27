import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import '../lib/src/sqlite_schema.dart';

void main() {
  test('logs database changes without row IDs or campaign values', () async {
    final database = sqlite3.openInMemory();
    final logger = _RecordingSqliteLogger();
    addTearDown(database.close);

    initializeRolemasterSqliteSchema(database, logger: logger);
    database.execute(
      '''
      INSERT INTO campaigns (id, name, created_at, updated_at)
      VALUES (?, ?, ?, ?)
      ''',
      <Object?>['campaign-secret-id', 'Private campaign name', 1, 1],
    );
    await Future<void>.delayed(Duration.zero);

    expect(logger.events, hasLength(1));
    expect(logger.events.single.$1, 'sqlite.transaction.committed');
    expect(logger.events.single.$2, <String, Object?>{
      'changes': <String, int>{'campaigns.insert': 1},
    });
    expect(logger.events.single.$2.toString(), isNot(contains('campaign-secret')));
    expect(logger.events.single.$2.toString(), isNot(contains('Private campaign')));

    database.execute('BEGIN');
    database.execute(
      'UPDATE campaigns SET name = ? WHERE id = ?',
      <Object?>['Still private', 'campaign-secret-id'],
    );
    database.execute('ROLLBACK');
    await Future<void>.delayed(Duration.zero);

    expect(logger.events, hasLength(2));
    expect(logger.events.last.$1, 'sqlite.transaction.rolled_back');
    expect(logger.events.last.$2, <String, Object?>{
      'changes': <String, int>{'campaigns.update': 1},
    });
  });
}

final class _RecordingSqliteLogger implements SqliteOperationLogger {
  final events = <(String, Map<String, Object?>)>[];

  @override
  void record(String event, Map<String, Object?> fields) {
    events.add((event, Map<String, Object?>.of(fields)));
  }
}

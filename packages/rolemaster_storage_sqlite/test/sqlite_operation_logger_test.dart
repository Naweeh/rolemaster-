import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('logs read and write failures without SQL or campaign values', () {
    final database = sqlite3.openInMemory();
    final logger = _RecordingSqliteLogger();
    addTearDown(database.close);
    observeSqliteDatabaseOperations(database, logger);

    expect(
      () => database.loggedSelect('SELECT private_campaign FROM missing_table'),
      throwsA(isA<SqliteException>()),
    );
    expect(
      () => database.loggedExecute(
        'INSERT INTO missing_table VALUES (?)',
        <Object?>['secret-campaign-value'],
      ),
      throwsA(isA<SqliteException>()),
    );

    expect(logger.events.map((event) => event.$1), <String>[
      'sqlite.repository.operation.failed',
      'sqlite.repository.operation.failed',
    ]);
    expect(logger.events[0].$2['operation'], 'read');
    expect(logger.events[1].$2['operation'], 'write');
    expect(logger.events.toString(), isNot(contains('private_campaign')));
    expect(logger.events.toString(), isNot(contains('secret-campaign-value')));
    expect(logger.events.toString(), isNot(contains('missing_table')));
  });

  test('logs database changes without row IDs or campaign values', () async {
    final database = sqlite3.openInMemory();
    final logger = _RecordingSqliteLogger();
    addTearDown(database.close);

    observeSqliteDatabaseOperations(database, logger);
    database.execute('CREATE TABLE campaigns (id TEXT PRIMARY KEY, name TEXT)');
    database.execute(
      'INSERT INTO campaigns (id, name) VALUES (?, ?)',
      <Object?>['campaign-secret-id', 'Private campaign name'],
    );
    await Future<void>.delayed(Duration.zero);

    expect(logger.events, hasLength(1));
    expect(logger.events.single.$1, 'sqlite.transaction.committed');
    expect(logger.events.single.$2, <String, Object?>{
      'changes': <String, int>{'campaigns.insert': 1},
    });
    expect(
      logger.events.single.$2.toString(),
      isNot(contains('campaign-secret')),
    );
    expect(
      logger.events.single.$2.toString(),
      isNot(contains('Private campaign')),
    );

    database.execute('BEGIN');
    database.execute('UPDATE campaigns SET name = ? WHERE id = ?', <Object?>[
      'Still private',
      'campaign-secret-id',
    ]);
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

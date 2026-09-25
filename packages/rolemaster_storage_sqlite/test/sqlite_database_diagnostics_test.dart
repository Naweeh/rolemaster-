import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test(
    'reports a healthy Rolemaster database without changing its version',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'rolemaster_diagnostics',
      );
      addTearDown(() => directory.delete(recursive: true));
      final path = '${directory.path}/db.sqlite';
      final repository = SqliteCampaignRepository.open(path);
      await repository.save(
        Campaign(id: 'campaign-1', name: 'Test', createdAt: DateTime.utc(2026)),
      );
      repository.close();

      final diagnostic = const SqliteDatabaseDiagnostics().inspect(path);
      expect(diagnostic.isHealthy, isTrue);
      expect(diagnostic.roleMasterSchemaPresent, isTrue);
      expect(diagnostic.schemaVersion, SqliteCampaignRepository.schemaVersion);

      final reopened = sqlite3.open(path, mode: OpenMode.readOnly);
      expect(reopened.userVersion, SqliteCampaignRepository.schemaVersion);
      reopened.close();
    },
  );

  test(
    'flags a structurally valid database without the Rolemaster schema',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'rolemaster_diagnostics_empty',
      );
      addTearDown(() => directory.delete(recursive: true));
      final path = '${directory.path}/empty.sqlite';
      final database = sqlite3.open(path);
      database.execute('CREATE TABLE unrelated (id INTEGER PRIMARY KEY)');
      database.close();

      final diagnostic = const SqliteDatabaseDiagnostics().inspect(path);
      expect(diagnostic.integrityMessages, <String>['ok']);
      expect(diagnostic.roleMasterSchemaPresent, isFalse);
      expect(diagnostic.isHealthy, isFalse);
    },
  );

  test('reports foreign key violations', () async {
    final directory = await Directory.systemTemp.createTemp(
      'rolemaster_diagnostics_fk',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/foreign-keys.sqlite';
    final database = sqlite3.open(path);
    database.execute('''
      CREATE TABLE campaigns (
        id TEXT PRIMARY KEY
      ) STRICT
    ''');
    database.execute('''
      CREATE TABLE child (
        id TEXT PRIMARY KEY,
        campaign_id TEXT REFERENCES campaigns(id)
      ) STRICT
    ''');
    database.execute('PRAGMA foreign_keys = OFF');
    database.execute("INSERT INTO child VALUES ('orphan', 'missing')");
    database.userVersion = SqliteCampaignRepository.schemaVersion;
    database.close();

    final diagnostic = const SqliteDatabaseDiagnostics().inspect(path);
    expect(diagnostic.roleMasterSchemaPresent, isTrue);
    expect(diagnostic.foreignKeyFailures, hasLength(1));
    expect(diagnostic.isHealthy, isFalse);
  });

  test('surfaces damaged SQLite files as diagnostic errors', () async {
    final directory = await Directory.systemTemp.createTemp(
      'rolemaster_diagnostics_bad',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/bad.sqlite';
    await File(path).writeAsString('not a sqlite database');

    expect(
      () => const SqliteDatabaseDiagnostics().inspect(path),
      throwsA(isA<SqliteException>()),
    );
  });
}

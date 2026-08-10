import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteEventHistoryRepository', () {
    test('persists event payload and metadata after reopening', () async {
      final fixture = await _createDatabaseFixture('event-reopen');
      addTearDown(fixture.dispose);

      final writer = SqliteEventHistoryRepository.open(fixture.path);
      await writer.append(
        DomainEvent(
          id: 'event-1',
          type: DomainEventTypes.worldLocationAdded,
          campaignId: 'campaign-1',
          occurredAt: DateTime.utc(2026, 8, 10, 12, 30),
          entityType: 'location',
          entityId: 'location-1',
          payload: const <String, Object?>{
            'name': 'Posada',
            'tags': <Object?>['interior', 'publico'],
            'visible': true,
          },
        ),
      );
      writer.close();

      final reader = SqliteEventHistoryRepository.open(fixture.path);
      final loaded = await reader.getById('event-1');
      reader.close();

      expect(loaded, isNotNull);
      expect(loaded!.type, DomainEventTypes.worldLocationAdded);
      expect(loaded.campaignId, 'campaign-1');
      expect(loaded.occurredAt, DateTime.utc(2026, 8, 10, 12, 30));
      expect(loaded.entityType, 'location');
      expect(loaded.entityId, 'location-1');
      expect(loaded.payload['name'], 'Posada');
      expect(loaded.payload['tags'], <Object?>['interior', 'publico']);
      expect(loaded.payload['visible'], isTrue);
    });

    test('is append-only and rejects duplicate event ids', () async {
      final fixture = await _createDatabaseFixture('event-duplicate');
      addTearDown(fixture.dispose);
      final repository = SqliteEventHistoryRepository.open(fixture.path);
      addTearDown(repository.close);

      final event = _event(
        id: 'event-1',
        type: DomainEventTypes.campaignUpdated,
      );
      await repository.append(event);

      await expectLater(
        repository.append(event),
        throwsA(isA<SqliteException>()),
      );
      final events = await repository.getForCampaign('campaign-1');
      expect(events, hasLength(1));
    });

    test('filters by type and limits to most recent matching events', () async {
      final fixture = await _createDatabaseFixture('event-filter');
      addTearDown(fixture.dispose);
      final repository = SqliteEventHistoryRepository.open(fixture.path);
      addTearDown(repository.close);

      await repository.append(
        _event(id: 'event-1', type: DomainEventTypes.worldCreated),
      );
      await repository.append(
        _event(id: 'event-2', type: DomainEventTypes.combatStarted),
      );
      await repository.append(
        _event(id: 'event-3', type: DomainEventTypes.worldCreated),
      );

      final all = await repository.getForCampaign('campaign-1');
      final filtered = await repository.getForCampaign(
        'campaign-1',
        type: DomainEventTypes.worldCreated,
        limit: 1,
      );

      expect(all.map((event) => event.id), <String>[
        'event-1',
        'event-2',
        'event-3',
      ]);
      expect(filtered.map((event) => event.id), <String>['event-3']);
    });

    test('migrates v4 to v5 without losing existing data', () async {
      final directory = await Directory.systemTemp.createTemp(
        'rolemaster_event_migration_',
      );
      final databasePath =
          '${directory.path}${Platform.pathSeparator}legacy-v4.db';
      addTearDown(() => directory.delete(recursive: true));
      _createLegacyV4Database(databasePath);

      final repository = SqliteEventHistoryRepository.open(databasePath);
      await repository.append(
        _event(id: 'event-new', type: DomainEventTypes.campaignUpdated),
      );
      repository.close();

      final database = sqlite3.open(databasePath);
      final version = database.select('PRAGMA user_version').single;
      final campaign = database
          .select("SELECT name FROM campaigns WHERE id = 'campaign-1'")
          .single;
      final world = database
          .select("SELECT name FROM worlds WHERE id = 'world-1'")
          .single;
      final calendar = database
          .select("SELECT name FROM calendars WHERE id = 'calendar-1'")
          .single;
      final events = database.select('SELECT id FROM domain_events');
      database.close();

      expect(
        version['user_version'],
        SqliteEventHistoryRepository.schemaVersion,
      );
      expect(campaign['name'], 'Campaña anterior');
      expect(world['name'], 'Mundo anterior');
      expect(calendar['name'], 'Calendario anterior');
      expect(events.single['id'], 'event-new');
    });
  });
}

DomainEvent _event({required String id, required String type}) {
  return DomainEvent(
    id: id,
    type: type,
    campaignId: 'campaign-1',
    occurredAt: DateTime.utc(2026, 8, 10, 12),
  );
}

Future<_DatabaseFixture> _createDatabaseFixture(String prefix) async {
  final directory = await Directory.systemTemp.createTemp('rolemaster_$prefix');
  final path = '${directory.path}${Platform.pathSeparator}rolemaster.db';
  final campaigns = SqliteCampaignRepository.open(path);
  await campaigns.save(
    Campaign(
      id: 'campaign-1',
      name: 'Campaña',
      createdAt: DateTime.utc(2026, 8, 10, 10),
    ),
  );
  campaigns.close();
  return _DatabaseFixture(path: path, directory: directory);
}

final class _DatabaseFixture {
  const _DatabaseFixture({required this.path, required this.directory});

  final String path;
  final Directory directory;

  Future<void> dispose() => directory.delete(recursive: true);
}

void _createLegacyV4Database(String path) {
  final database = sqlite3.open(path);
  database.execute('PRAGMA foreign_keys = ON');
  database.execute('''
    CREATE TABLE campaigns (
      id TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      archived_at INTEGER,
      description TEXT,
      tags_json TEXT NOT NULL DEFAULT '[]',
      ai_enabled INTEGER NOT NULL DEFAULT 1,
      voice_enabled INTEGER NOT NULL DEFAULT 1,
      audio_enabled INTEGER NOT NULL DEFAULT 1
    ) STRICT
  ''');
  database.execute('''
    CREATE TABLE worlds (
      id TEXT NOT NULL PRIMARY KEY,
      campaign_id TEXT NOT NULL,
      name TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      description TEXT,
      tags_json TEXT NOT NULL DEFAULT '[]',
      FOREIGN KEY (campaign_id) REFERENCES campaigns(id)
    ) STRICT
  ''');
  database.execute('''
    CREATE TABLE calendars (
      id TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      months_json TEXT NOT NULL,
      weekdays_json TEXT NOT NULL,
      hours_per_day INTEGER NOT NULL,
      minutes_per_hour INTEGER NOT NULL,
      starting_weekday_index INTEGER NOT NULL
    ) STRICT
  ''');

  final timestamp = DateTime.utc(2026, 8, 10, 10).millisecondsSinceEpoch;
  database.execute(
    '''
    INSERT INTO campaigns (
      id, name, created_at, updated_at, archived_at, description, tags_json,
      ai_enabled, voice_enabled, audio_enabled
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    <Object?>[
      'campaign-1',
      'Campaña anterior',
      timestamp,
      timestamp,
      null,
      null,
      '[]',
      1,
      1,
      1,
    ],
  );
  database.execute(
    '''
    INSERT INTO worlds (
      id, campaign_id, name, created_at, updated_at, description, tags_json
    ) VALUES (?, ?, ?, ?, ?, ?, ?)
    ''',
    <Object?>[
      'world-1',
      'campaign-1',
      'Mundo anterior',
      timestamp,
      timestamp,
      null,
      '[]',
    ],
  );
  database.execute(
    '''
    INSERT INTO calendars (
      id, name, months_json, weekdays_json, hours_per_day,
      minutes_per_hour, starting_weekday_index
    ) VALUES (?, ?, ?, ?, ?, ?, ?)
    ''',
    <Object?>[
      'calendar-1',
      'Calendario anterior',
      '[{"name":"Mes","days":30}]',
      '["Día"]',
      24,
      60,
      0,
    ],
  );
  database.execute('PRAGMA user_version = 4');
  database.close();
}

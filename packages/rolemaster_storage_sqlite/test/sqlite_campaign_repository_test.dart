import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteCampaignRepository', () {
    test(
      'saves and loads a campaign preserving lifecycle, metadata and configuration',
      () async {
        final repository = SqliteCampaignRepository.inMemory();
        addTearDown(repository.close);

        final campaign = Campaign(
          id: 'campaign-1',
          name: 'La Corona Perdida',
          createdAt: DateTime.utc(2026, 8, 10, 10),
          updatedAt: DateTime.utc(2026, 8, 10, 11),
          metadata: CampaignMetadata(
            description: 'Campaña presencial',
            tags: <String>['principal', 'fantasia'],
          ),
          configuration: const CampaignConfiguration(
            aiEnabled: false,
            voiceEnabled: true,
            audioEnabled: false,
          ),
        ).archive(at: DateTime.utc(2026, 8, 10, 12));

        await repository.save(campaign);
        final loaded = await repository.getById(campaign.id);

        expect(loaded, isNotNull);
        expect(loaded!.id, campaign.id);
        expect(loaded.name, campaign.name);
        expect(loaded.createdAt, campaign.createdAt);
        expect(loaded.updatedAt, campaign.updatedAt);
        expect(loaded.archivedAt, campaign.archivedAt);
        expect(loaded.metadata.description, 'Campaña presencial');
        expect(loaded.metadata.tags, <String>['principal', 'fantasia']);
        expect(loaded.configuration.aiEnabled, isFalse);
        expect(loaded.configuration.voiceEnabled, isTrue);
        expect(loaded.configuration.audioEnabled, isFalse);
      },
    );

    test('hides archived campaigns unless explicitly requested', () async {
      final repository = SqliteCampaignRepository.inMemory();
      addTearDown(repository.close);

      final active = Campaign(
        id: 'active',
        name: 'Activa',
        createdAt: DateTime.utc(2026, 8, 10, 10),
      );
      final archived = Campaign(
        id: 'archived',
        name: 'Archivada',
        createdAt: DateTime.utc(2026, 8, 10, 10),
      ).archive(at: DateTime.utc(2026, 8, 10, 12));

      await repository.save(active);
      await repository.save(archived);

      final visible = await repository.getAll();
      final all = await repository.getAll(includeArchived: true);

      expect(visible.map((campaign) => campaign.id), <String>['active']);
      expect(
        all.map((campaign) => campaign.id),
        containsAll(<String>['active', 'archived']),
      );
    });

    test('upserts campaign updates by id', () async {
      final repository = SqliteCampaignRepository.inMemory();
      addTearDown(repository.close);

      final campaign = Campaign(
        id: 'campaign-1',
        name: 'Original',
        createdAt: DateTime.utc(2026, 8, 10, 10),
      );
      final updated = campaign.update(
        name: 'Renombrada',
        metadata: CampaignMetadata(description: 'Actualizada'),
        configuration: const CampaignConfiguration(aiEnabled: false),
        at: DateTime.utc(2026, 8, 10, 11),
      );

      await repository.save(campaign);
      await repository.save(updated);

      final loaded = await repository.getById(campaign.id);
      expect(loaded?.name, 'Renombrada');
      expect(loaded?.metadata.description, 'Actualizada');
      expect(loaded?.configuration.aiEnabled, isFalse);
      expect((await repository.getAll(includeArchived: true)), hasLength(1));
    });

    test(
      'persists a campaign after closing and reopening the database',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'rolemaster_sqlite_',
        );
        final databasePath =
            '${directory.path}${Platform.pathSeparator}campaign.db';
        addTearDown(() => directory.delete(recursive: true));

        final campaign = Campaign(
          id: 'campaign-1',
          name: 'Persistente',
          createdAt: DateTime.utc(2026, 8, 10, 10),
          metadata: CampaignMetadata(tags: <String>['persistente']),
          configuration: const CampaignConfiguration(audioEnabled: false),
        );

        final writer = SqliteCampaignRepository.open(databasePath);
        await writer.save(campaign);
        writer.close();

        final reader = SqliteCampaignRepository.open(databasePath);
        final loaded = await reader.getById(campaign.id);
        reader.close();

        expect(loaded, isNotNull);
        expect(loaded!.id, campaign.id);
        expect(loaded.name, campaign.name);
        expect(loaded.createdAt, campaign.createdAt);
        expect(loaded.metadata.tags, <String>['persistente']);
        expect(loaded.configuration.audioEnabled, isFalse);
      },
    );

    test(
      'migrates a schema v1 database to v2 without losing campaigns',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'rolemaster_sqlite_v1_',
        );
        final databasePath =
            '${directory.path}${Platform.pathSeparator}campaign-v1.db';
        addTearDown(() => directory.delete(recursive: true));

        final legacy = sqlite3.open(databasePath);
        legacy.execute('''
        CREATE TABLE campaigns (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          archived_at INTEGER
        ) STRICT
      ''');
        legacy.execute(
          '''
        INSERT INTO campaigns (
          id,
          name,
          created_at,
          updated_at,
          archived_at
        ) VALUES (?, ?, ?, ?, ?)
        ''',
          <Object?>[
            'legacy',
            'Campaña anterior',
            DateTime.utc(2026, 8, 10, 10).millisecondsSinceEpoch,
            DateTime.utc(2026, 8, 10, 11).millisecondsSinceEpoch,
            null,
          ],
        );
        legacy.execute('PRAGMA user_version = 1');
        legacy.close();

        final repository = SqliteCampaignRepository.open(databasePath);
        final loaded = await repository.getById('legacy');
        repository.close();

        expect(loaded, isNotNull);
        expect(loaded!.name, 'Campaña anterior');
        expect(loaded.metadata.description, isNull);
        expect(loaded.metadata.tags, isEmpty);
        expect(loaded.configuration.aiEnabled, isTrue);
        expect(loaded.configuration.voiceEnabled, isTrue);
        expect(loaded.configuration.audioEnabled, isTrue);

        final migrated = sqlite3.open(databasePath);
        final version = migrated.select('PRAGMA user_version').single;
        migrated.close();
        expect(version['user_version'], SqliteCampaignRepository.schemaVersion);
      },
    );
  });
}

import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteWorldRepository', () {
    test('persists world hierarchy and metadata after reopening', () async {
      final directory = await Directory.systemTemp.createTemp(
        'rolemaster_world_sqlite_',
      );
      final databasePath = '${directory.path}${Platform.pathSeparator}world.db';
      addTearDown(() => directory.delete(recursive: true));

      final campaignRepository = SqliteCampaignRepository.open(databasePath);
      await campaignRepository.save(
        Campaign(
          id: 'campaign-1',
          name: 'Campaña',
          createdAt: DateTime.utc(2026, 8, 10, 10),
        ),
      );
      campaignRepository.close();

      final writer = SqliteWorldRepository.open(databasePath);
      final world = World(
        id: 'world-1',
        campaignId: 'campaign-1',
        name: 'Tierra Media',
        createdAt: DateTime.utc(2026, 8, 10, 11),
        metadata: WorldMetadata(
          description: 'Mundo principal',
          tags: <String>['fantasia', 'principal'],
        ),
      );
      final region = Region(
        id: 'region-1',
        worldId: 'world-1',
        name: 'Eriador',
        createdAt: DateTime.utc(2026, 8, 10, 12),
      );
      final subregion = Region(
        id: 'region-2',
        worldId: 'world-1',
        name: 'La Comarca',
        parentRegionId: 'region-1',
        createdAt: DateTime.utc(2026, 8, 10, 13),
      );
      final town = Location(
        id: 'location-1',
        worldId: 'world-1',
        name: 'Hobbiton',
        regionId: 'region-2',
        createdAt: DateTime.utc(2026, 8, 10, 14),
      );
      final inn = Location(
        id: 'location-2',
        worldId: 'world-1',
        name: 'Posada',
        regionId: 'region-2',
        parentLocationId: 'location-1',
        createdAt: DateTime.utc(2026, 8, 10, 15),
        metadata: WorldMetadata(tags: <String>['interior']),
      );

      await writer.saveWorld(world);
      await writer.saveRegion(region);
      await writer.saveRegion(subregion);
      await writer.saveLocation(town);
      await writer.saveLocation(inn);
      writer.close();

      final reader = SqliteWorldRepository.open(databasePath);
      final loadedWorld = await reader.getWorldById('world-1');
      final regions = await reader.getRegionsForWorld('world-1');
      final locations = await reader.getLocationsForWorld('world-1');
      reader.close();

      expect(loadedWorld, isNotNull);
      expect(loadedWorld!.campaignId, 'campaign-1');
      expect(loadedWorld.metadata.description, 'Mundo principal');
      expect(loadedWorld.metadata.tags, <String>['fantasia', 'principal']);
      expect(regions, hasLength(2));
      expect(
        regions.singleWhere((item) => item.id == 'region-2').parentRegionId,
        'region-1',
      );
      expect(locations, hasLength(2));
      expect(
        locations
            .singleWhere((item) => item.id == 'location-2')
            .parentLocationId,
        'location-1',
      );
      expect(
        locations.singleWhere((item) => item.id == 'location-2').metadata.tags,
        <String>['interior'],
      );
    });

    test('lists worlds only for the requested campaign', () async {
      final directory = await Directory.systemTemp.createTemp(
        'rolemaster_world_list_',
      );
      final databasePath =
          '${directory.path}${Platform.pathSeparator}world-list.db';
      addTearDown(() => directory.delete(recursive: true));

      final campaignRepository = SqliteCampaignRepository.open(databasePath);
      await campaignRepository.save(
        Campaign(
          id: 'campaign-1',
          name: 'Uno',
          createdAt: DateTime.utc(2026, 8, 10, 10),
        ),
      );
      await campaignRepository.save(
        Campaign(
          id: 'campaign-2',
          name: 'Dos',
          createdAt: DateTime.utc(2026, 8, 10, 10),
        ),
      );
      campaignRepository.close();

      final repository = SqliteWorldRepository.open(databasePath);
      await repository.saveWorld(
        World(
          id: 'world-1',
          campaignId: 'campaign-1',
          name: 'Primero',
          createdAt: DateTime.utc(2026, 8, 10, 11),
        ),
      );
      await repository.saveWorld(
        World(
          id: 'world-2',
          campaignId: 'campaign-2',
          name: 'Segundo',
          createdAt: DateTime.utc(2026, 8, 10, 11),
        ),
      );

      final worlds = await repository.getWorldsForCampaign('campaign-1');
      repository.close();

      expect(worlds.map((world) => world.id), <String>['world-1']);
    });

    test(
      'migrates schema v2 to current schema without losing campaign data',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'rolemaster_world_migration_',
        );
        final databasePath =
            '${directory.path}${Platform.pathSeparator}legacy-v2.db';
        addTearDown(() => directory.delete(recursive: true));

        final legacy = sqlite3.open(databasePath);
        legacy.execute('''
        CREATE TABLE campaigns (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          archived_at INTEGER,
          description TEXT,
          tags_json TEXT NOT NULL DEFAULT '[]',
          ai_enabled INTEGER NOT NULL DEFAULT 1 CHECK (ai_enabled IN (0, 1)),
          voice_enabled INTEGER NOT NULL DEFAULT 1 CHECK (voice_enabled IN (0, 1)),
          audio_enabled INTEGER NOT NULL DEFAULT 1 CHECK (audio_enabled IN (0, 1))
        ) STRICT
      ''');
        legacy.execute(
          '''
        INSERT INTO campaigns (
          id, name, created_at, updated_at, archived_at,
          description, tags_json, ai_enabled, voice_enabled, audio_enabled
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
          <Object?>[
            'campaign-legacy',
            'Anterior',
            DateTime.utc(2026, 8, 10, 10).millisecondsSinceEpoch,
            DateTime.utc(2026, 8, 10, 10).millisecondsSinceEpoch,
            null,
            'Conservar',
            '["legacy"]',
            1,
            1,
            1,
          ],
        );
        legacy.execute('PRAGMA user_version = 2');
        legacy.close();

        final worldRepository = SqliteWorldRepository.open(databasePath);
        await worldRepository.saveWorld(
          World(
            id: 'world-new',
            campaignId: 'campaign-legacy',
            name: 'Mundo nuevo',
            createdAt: DateTime.utc(2026, 8, 10, 12),
          ),
        );
        worldRepository.close();

        final campaignRepository = SqliteCampaignRepository.open(databasePath);
        final campaign = await campaignRepository.getById('campaign-legacy');
        campaignRepository.close();

        expect(campaign, isNotNull);
        expect(campaign!.name, 'Anterior');
        expect(campaign.metadata.description, 'Conservar');
        expect(campaign.metadata.tags, <String>['legacy']);

        final migrated = sqlite3.open(databasePath);
        final version = migrated.select('PRAGMA user_version').single;
        final worlds = migrated.select('SELECT id FROM worlds');
        migrated.close();

        expect(version['user_version'], SqliteWorldRepository.schemaVersion);
        expect(worlds.single['id'], 'world-new');
      },
    );
  });
}

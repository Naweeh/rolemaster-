import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_state_sqlite.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteCharacterRepository', () {
    test('persists character metadata after reopening', () async {
      final fixture = await _createFixture('character-reopen');
      addTearDown(fixture.dispose);

      final writer = SqliteCharacterRepository.open(fixture.path);
      await writer.save(
        Character(
          id: 'character-1',
          campaignId: 'campaign-1',
          name: 'Aria',
          createdAt: DateTime.utc(2026, 8, 10, 12),
          metadata: CharacterMetadata(
            playerName: 'Alex',
            description: 'Exploradora',
            notes: 'Lleva un mapa antiguo.',
            tags: <String>['heroina', 'grupo-a'],
          ),
        ),
      );
      writer.close();

      final reader = SqliteCharacterRepository.open(fixture.path);
      final loaded = await reader.getById('character-1');
      reader.close();

      expect(loaded, isNotNull);
      expect(loaded!.campaignId, 'campaign-1');
      expect(loaded.name, 'Aria');
      expect(loaded.metadata.playerName, 'Alex');
      expect(loaded.metadata.description, 'Exploradora');
      expect(loaded.metadata.notes, 'Lleva un mapa antiguo.');
      expect(loaded.metadata.tags, <String>['heroina', 'grupo-a']);
    });

    test('filters by campaign and archived state', () async {
      final fixture = await _createFixture(
        'character-filter',
        secondCampaign: true,
      );
      addTearDown(fixture.dispose);
      final repository = SqliteCharacterRepository.open(fixture.path);
      addTearDown(repository.close);

      await repository.save(
        Character(
          id: 'active-1',
          campaignId: 'campaign-1',
          name: 'Activa',
          createdAt: DateTime.utc(2026, 8, 10, 10),
        ),
      );
      await repository.save(
        Character(
          id: 'archived-1',
          campaignId: 'campaign-1',
          name: 'Archivada',
          createdAt: DateTime.utc(2026, 8, 10, 10),
        ).archive(at: DateTime.utc(2026, 8, 10, 11)),
      );
      await repository.save(
        Character(
          id: 'other-1',
          campaignId: 'campaign-2',
          name: 'Otra campaña',
          createdAt: DateTime.utc(2026, 8, 10, 10),
        ),
      );

      final active = await repository.getForCampaign('campaign-1');
      final all = await repository.getForCampaign(
        'campaign-1',
        includeArchived: true,
      );
      final other = await repository.getForCampaign('campaign-2');

      expect(active.map((character) => character.id), <String>['active-1']);
      expect(all.map((character) => character.id).toSet(), <String>{
        'active-1',
        'archived-1',
      });
      expect(other.map((character) => character.id), <String>['other-1']);
    });

    test('updates an existing character without duplicating it', () async {
      final fixture = await _createFixture('character-update');
      addTearDown(fixture.dispose);
      final repository = SqliteCharacterRepository.open(fixture.path);
      addTearDown(repository.close);

      final original = Character(
        id: 'character-1',
        campaignId: 'campaign-1',
        name: 'Aria',
        createdAt: DateTime.utc(2026, 8, 10, 10),
      );
      await repository.save(original);
      await repository.save(
        original.update(
          name: 'Aria Renombrada',
          metadata: CharacterMetadata(notes: 'Actualizada'),
          at: DateTime.utc(2026, 8, 10, 11),
        ),
      );

      final all = await repository.getForCampaign('campaign-1');
      expect(all, hasLength(1));
      expect(all.single.name, 'Aria Renombrada');
      expect(all.single.metadata.notes, 'Actualizada');
      expect(all.single.createdAt, DateTime.utc(2026, 8, 10, 10));
    });

    test(
      'migrates v6 to current schema preserving event history and state',
      () async {
        final fixture = await _createFixture('character-migration');
        addTearDown(fixture.dispose);

        final events = SqliteEventHistoryRepository.open(fixture.path);
        await events.append(
          DomainEvent(
            id: 'event-before-character',
            type: DomainEventTypes.campaignUpdated,
            campaignId: 'campaign-1',
            occurredAt: DateTime.utc(2026, 8, 10, 11),
          ),
        );
        events.close();

        final states = SqliteCampaignStateRepository.open(fixture.path);
        expect(
          await states.save(
            CampaignState(
              campaignId: 'campaign-1',
              revision: 1,
              updatedAt: DateTime.utc(2026, 8, 10, 12),
            ),
            expectedRevision: 0,
          ),
          isTrue,
        );
        states.close();

        final legacy = sqlite3.open(fixture.path);
        legacy.execute('DROP TABLE scene_entity_positions');
        legacy.execute('DROP TABLE scene_layers');
        legacy.execute('DROP TABLE scene_maps');
        legacy.execute('DROP TABLE item_instances');
        legacy.execute('DROP TABLE character_skills');
        legacy.execute('DROP TABLE campaign_rulesets');
        legacy.execute('DROP TABLE ruleset_packages');
        legacy.execute('DROP TABLE creatures');
        legacy.execute('DROP TABLE npcs');
        legacy.execute('DROP TABLE characters');
        legacy.execute('PRAGMA user_version = 6');
        legacy.close();

        final characters = SqliteCharacterRepository.open(fixture.path);
        await characters.save(
          Character(
            id: 'character-new',
            campaignId: 'campaign-1',
            name: 'Nueva',
            createdAt: DateTime.utc(2026, 8, 10, 13),
          ),
        );
        characters.close();

        final reopenedEvents = SqliteEventHistoryRepository.open(fixture.path);
        final event = await reopenedEvents.getById('event-before-character');
        reopenedEvents.close();
        final reopenedStates = SqliteCampaignStateRepository.open(fixture.path);
        final state = await reopenedStates.getByCampaignId('campaign-1');
        reopenedStates.close();
        final migrated = sqlite3.open(fixture.path);
        final version = migrated.select('PRAGMA user_version').single;
        final characterRows = migrated.select(
          "SELECT id FROM characters WHERE id = 'character-new'",
        );
        final npcTables = migrated.select(
          "SELECT name FROM sqlite_master "
          "WHERE type = 'table' AND name = 'npcs'",
        );
        final creatureTables = migrated.select(
          "SELECT name FROM sqlite_master "
          "WHERE type = 'table' AND name = 'creatures'",
        );
        migrated.close();

        expect(
          version['user_version'],
          SqliteCharacterRepository.schemaVersion,
        );
        expect(characterRows.single['id'], 'character-new');
        expect(npcTables, hasLength(1));
        expect(creatureTables, hasLength(1));
        expect(event, isNotNull);
        expect(state, isNotNull);
        expect(state!.revision, 1);
      },
    );
  });
}

Future<_Fixture> _createFixture(
  String prefix, {
  bool secondCampaign = false,
}) async {
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
  if (secondCampaign) {
    await campaigns.save(
      Campaign(
        id: 'campaign-2',
        name: 'Segunda',
        createdAt: DateTime.utc(2026, 8, 10, 10),
      ),
    );
  }
  campaigns.close();
  return _Fixture(path: path, directory: directory);
}

final class _Fixture {
  const _Fixture({required this.path, required this.directory});

  final String path;
  final Directory directory;

  Future<void> dispose() => directory.delete(recursive: true);
}

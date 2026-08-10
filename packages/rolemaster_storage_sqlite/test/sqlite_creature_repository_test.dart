import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_state_sqlite.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteCreatureRepository', () {
    test('persists metadata and placement after reopening', () async {
      final fixture = await _createFixture('creature-reopen', withWorld: true);
      addTearDown(fixture.dispose);

      final writer = SqliteCreatureRepository.open(fixture.path);
      await writer.save(
        Creature(
          id: 'creature-1',
          campaignId: 'campaign-1',
          name: 'Lobo Gris',
          createdAt: DateTime.utc(2026, 8, 10, 12),
          metadata: CreatureMetadata(
            species: 'Lobo',
            category: 'Bestia',
            description: 'Depredador del bosque.',
            notes: 'Evita el fuego.',
            tags: <String>['salvaje', 'bosque'],
          ),
          placement: CreaturePlacement(
            worldId: 'world-1',
            locationId: 'location-1',
          ),
        ),
      );
      writer.close();

      final reader = SqliteCreatureRepository.open(fixture.path);
      final loaded = await reader.getById('creature-1');
      reader.close();

      expect(loaded, isNotNull);
      expect(loaded!.metadata.species, 'Lobo');
      expect(loaded.metadata.category, 'Bestia');
      expect(loaded.metadata.tags, <String>['salvaje', 'bosque']);
      expect(loaded.placement.worldId, 'world-1');
      expect(loaded.placement.locationId, 'location-1');
    });

    test('filters archived creatures by campaign', () async {
      final fixture = await _createFixture(
        'creature-filter',
        secondCampaign: true,
      );
      addTearDown(fixture.dispose);
      final repository = SqliteCreatureRepository.open(fixture.path);
      addTearDown(repository.close);

      await repository.save(
        Creature(
          id: 'active-1',
          campaignId: 'campaign-1',
          name: 'Lobo',
          createdAt: DateTime.utc(2026, 8, 10, 10),
          metadata: CreatureMetadata(species: 'Lobo'),
        ),
      );
      await repository.save(
        Creature(
          id: 'archived-1',
          campaignId: 'campaign-1',
          name: 'Oso',
          createdAt: DateTime.utc(2026, 8, 10, 10),
          metadata: CreatureMetadata(species: 'Oso'),
        ).archive(at: DateTime.utc(2026, 8, 10, 11)),
      );
      await repository.save(
        Creature(
          id: 'other-1',
          campaignId: 'campaign-2',
          name: 'Águila',
          createdAt: DateTime.utc(2026, 8, 10, 10),
          metadata: CreatureMetadata(species: 'Águila'),
        ),
      );

      expect(
        (await repository.getForCampaign('campaign-1'))
            .map((creature) => creature.id),
        <String>['active-1'],
      );
      expect(
        (await repository.getForCampaign(
          'campaign-1',
          includeArchived: true,
        )).map((creature) => creature.id).toSet(),
        <String>{'active-1', 'archived-1'},
      );
    });

    test('migrates v8 to v9 preserving prior domain data', () async {
      final fixture = await _createFixture('creature-migration');
      addTearDown(fixture.dispose);

      final characters = SqliteCharacterRepository.open(fixture.path);
      await characters.save(
        Character(
          id: 'character-1',
          campaignId: 'campaign-1',
          name: 'Aria',
          createdAt: DateTime.utc(2026, 8, 10, 10),
        ),
      );
      characters.close();

      final npcs = SqliteNpcRepository.open(fixture.path);
      await npcs.save(
        Npc(
          id: 'npc-1',
          campaignId: 'campaign-1',
          name: 'Guardián',
          createdAt: DateTime.utc(2026, 8, 10, 10),
          metadata: NpcMetadata(nativeLanguage: 'Común'),
        ),
      );
      npcs.close();

      final events = SqliteEventHistoryRepository.open(fixture.path);
      await events.append(
        DomainEvent(
          id: 'event-before-creature',
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
      legacy.execute('DROP TABLE creatures');
      legacy.execute('PRAGMA user_version = 8');
      legacy.close();

      final creatures = SqliteCreatureRepository.open(fixture.path);
      await creatures.save(
        Creature(
          id: 'creature-new',
          campaignId: 'campaign-1',
          name: 'Lobo',
          createdAt: DateTime.utc(2026, 8, 10, 13),
          metadata: CreatureMetadata(species: 'Lobo'),
        ),
      );
      creatures.close();

      final migrated = sqlite3.open(fixture.path);
      final version = migrated.select('PRAGMA user_version').single;
      final creatureRows = migrated.select(
        "SELECT id FROM creatures WHERE id = 'creature-new'",
      );
      migrated.close();

      final reopenedCharacters = SqliteCharacterRepository.open(fixture.path);
      final character = await reopenedCharacters.getById('character-1');
      reopenedCharacters.close();
      final reopenedNpcs = SqliteNpcRepository.open(fixture.path);
      final npc = await reopenedNpcs.getById('npc-1');
      reopenedNpcs.close();
      final reopenedEvents = SqliteEventHistoryRepository.open(fixture.path);
      final event = await reopenedEvents.getById('event-before-creature');
      reopenedEvents.close();
      final reopenedStates = SqliteCampaignStateRepository.open(fixture.path);
      final state = await reopenedStates.getByCampaignId('campaign-1');
      reopenedStates.close();

      expect(version['user_version'], SqliteCreatureRepository.schemaVersion);
      expect(creatureRows.single['id'], 'creature-new');
      expect(character, isNotNull);
      expect(npc, isNotNull);
      expect(event, isNotNull);
      expect(state!.revision, 1);
    });
  });
}

Future<_Fixture> _createFixture(
  String prefix, {
  bool secondCampaign = false,
  bool withWorld = false,
}) async {
  final directory = await Directory.systemTemp.createTemp('rolemaster_$prefix');
  final path = '${directory.path}${Platform.pathSeparator}rolemaster.db';
  final campaigns = SqliteCampaignRepository.open(path);
  await campaigns.save(
    Campaign(
      id: 'campaign-1',
      name: 'Campaña',
      createdAt: DateTime.utc(2026, 8, 10, 9),
    ),
  );
  if (secondCampaign) {
    await campaigns.save(
      Campaign(
        id: 'campaign-2',
        name: 'Segunda',
        createdAt: DateTime.utc(2026, 8, 10, 9),
      ),
    );
  }
  campaigns.close();

  if (withWorld) {
    final worlds = SqliteWorldRepository.open(path);
    await worlds.saveWorld(
      World(
        id: 'world-1',
        campaignId: 'campaign-1',
        name: 'Mundo',
        createdAt: DateTime.utc(2026, 8, 10, 9),
      ),
    );
    await worlds.saveLocation(
      Location(
        id: 'location-1',
        worldId: 'world-1',
        name: 'Bosque',
        createdAt: DateTime.utc(2026, 8, 10, 9),
      ),
    );
    worlds.close();
  }

  return _Fixture(path: path, directory: directory);
}

final class _Fixture {
  const _Fixture({required this.path, required this.directory});

  final String path;
  final Directory directory;

  Future<void> dispose() => directory.delete(recursive: true);
}

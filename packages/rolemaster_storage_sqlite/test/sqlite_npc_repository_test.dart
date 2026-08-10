import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_state_sqlite.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteNpcRepository', () {
    test('persists language profile, metadata and placement', () async {
      final fixture = await _createFixture('npc-reopen', withWorld: true);
      addTearDown(fixture.dispose);

      final writer = SqliteNpcRepository.open(fixture.path);
      await writer.save(
        Npc(
          id: 'npc-1',
          campaignId: 'campaign-1',
          name: 'Guardián',
          createdAt: DateTime.utc(2026, 8, 10, 12),
          metadata: NpcMetadata(
            nativeLanguage: 'Sindarin',
            knownLanguages: <String>['Común'],
            role: 'Guardián',
            description: 'Custodia la entrada.',
            notes: 'Confía en los elfos.',
            tags: <String>['aliado', 'elfo'],
          ),
          placement: NpcPlacement(worldId: 'world-1', locationId: 'location-1'),
        ),
      );
      writer.close();

      final reader = SqliteNpcRepository.open(fixture.path);
      final loaded = await reader.getById('npc-1');
      reader.close();

      expect(loaded, isNotNull);
      expect(loaded!.metadata.nativeLanguage, 'Sindarin');
      expect(loaded.metadata.knownLanguages, <String>['Común']);
      expect(loaded.metadata.role, 'Guardián');
      expect(loaded.metadata.description, 'Custodia la entrada.');
      expect(loaded.metadata.notes, 'Confía en los elfos.');
      expect(loaded.metadata.tags, <String>['aliado', 'elfo']);
      expect(loaded.placement.worldId, 'world-1');
      expect(loaded.placement.locationId, 'location-1');
    });

    test('filters archived NPCs by campaign', () async {
      final fixture = await _createFixture('npc-filter', secondCampaign: true);
      addTearDown(fixture.dispose);
      final repository = SqliteNpcRepository.open(fixture.path);
      addTearDown(repository.close);

      await repository.save(
        Npc(
          id: 'npc-active',
          campaignId: 'campaign-1',
          name: 'Activo',
          createdAt: DateTime.utc(2026, 8, 10, 10),
          metadata: NpcMetadata(nativeLanguage: 'Común'),
        ),
      );
      await repository.save(
        Npc(
          id: 'npc-archived',
          campaignId: 'campaign-1',
          name: 'Archivado',
          createdAt: DateTime.utc(2026, 8, 10, 10),
          metadata: NpcMetadata(nativeLanguage: 'Común'),
        ).archive(at: DateTime.utc(2026, 8, 10, 11)),
      );
      await repository.save(
        Npc(
          id: 'npc-other',
          campaignId: 'campaign-2',
          name: 'Otro',
          createdAt: DateTime.utc(2026, 8, 10, 10),
          metadata: NpcMetadata(nativeLanguage: 'Común'),
        ),
      );

      final active = await repository.getForCampaign('campaign-1');
      final all = await repository.getForCampaign(
        'campaign-1',
        includeArchived: true,
      );
      final other = await repository.getForCampaign('campaign-2');

      expect(active.map((npc) => npc.id), <String>['npc-active']);
      expect(all.map((npc) => npc.id).toSet(), <String>{
        'npc-active',
        'npc-archived',
      });
      expect(other.map((npc) => npc.id), <String>['npc-other']);
    });

    test('updates and unplaces an existing NPC without duplication', () async {
      final fixture = await _createFixture('npc-update', withWorld: true);
      addTearDown(fixture.dispose);
      final repository = SqliteNpcRepository.open(fixture.path);
      addTearDown(repository.close);

      final original = Npc(
        id: 'npc-1',
        campaignId: 'campaign-1',
        name: 'Guardián',
        createdAt: DateTime.utc(2026, 8, 10, 10),
        metadata: NpcMetadata(nativeLanguage: 'Común'),
        placement: NpcPlacement(worldId: 'world-1', locationId: 'location-1'),
      );
      await repository.save(original);
      await repository.save(
        original.update(
          name: 'Guardián Mayor',
          metadata: NpcMetadata(
            nativeLanguage: 'Común',
            knownLanguages: <String>['Khuzdul'],
          ),
          placement: NpcPlacement.unplaced(),
          at: DateTime.utc(2026, 8, 10, 11),
        ),
      );

      final all = await repository.getForCampaign('campaign-1');
      expect(all, hasLength(1));
      expect(all.single.name, 'Guardián Mayor');
      expect(all.single.metadata.knownLanguages, <String>['Khuzdul']);
      expect(all.single.placement.isPlaced, isFalse);
    });

    test('migrates v7 to v8 preserving character, event and state', () async {
      final fixture = await _createFixture('npc-migration');
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

      final events = SqliteEventHistoryRepository.open(fixture.path);
      await events.append(
        DomainEvent(
          id: 'event-before-npc',
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
      legacy.execute('DROP TABLE item_instances');
      legacy.execute('DROP TABLE character_skills');
      legacy.execute('DROP TABLE campaign_rulesets');
      legacy.execute('DROP TABLE ruleset_packages');
      legacy.execute('DROP TABLE creatures');
      legacy.execute('DROP TABLE npcs');
      legacy.execute('PRAGMA user_version = 7');
      legacy.close();

      final npcs = SqliteNpcRepository.open(fixture.path);
      await npcs.save(
        Npc(
          id: 'npc-new',
          campaignId: 'campaign-1',
          name: 'Nuevo',
          createdAt: DateTime.utc(2026, 8, 10, 13),
          metadata: NpcMetadata(nativeLanguage: 'Común'),
        ),
      );
      npcs.close();

      final reopenedCharacters = SqliteCharacterRepository.open(fixture.path);
      final character = await reopenedCharacters.getById('character-1');
      reopenedCharacters.close();
      final reopenedEvents = SqliteEventHistoryRepository.open(fixture.path);
      final event = await reopenedEvents.getById('event-before-npc');
      reopenedEvents.close();
      final reopenedStates = SqliteCampaignStateRepository.open(fixture.path);
      final state = await reopenedStates.getByCampaignId('campaign-1');
      reopenedStates.close();
      final migrated = sqlite3.open(fixture.path);
      final version = migrated.select('PRAGMA user_version').single;
      final npcRows = migrated.select(
        "SELECT id FROM npcs WHERE id = 'npc-new'",
      );
      migrated.close();

      expect(version['user_version'], SqliteNpcRepository.schemaVersion);
      expect(npcRows.single['id'], 'npc-new');
      expect(character, isNotNull);
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
        name: 'Posada',
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

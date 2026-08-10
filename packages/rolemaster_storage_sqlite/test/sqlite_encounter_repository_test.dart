import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('encounter persists participants and lifecycle across reopen', () async {
    final temp = await Directory.systemTemp.createTemp('rolemaster-encounter-');
    final path = '${temp.path}/encounter.sqlite';
    addTearDown(() async => temp.delete(recursive: true));

    final campaignRepository = SqliteCampaignRepository.open(path);
    await campaignRepository.save(
      Campaign(
        id: 'campaign-1',
        name: 'Campaign',
        createdAt: DateTime.utc(2026, 8, 10, 21),
      ),
    );
    campaignRepository.close();

    final repository = SqliteEncounterRepository.open(path);
    final createdAt = DateTime.utc(2026, 8, 10, 21, 10);
    final startedAt = createdAt.add(const Duration(minutes: 2));
    final closedAt = startedAt.add(const Duration(minutes: 5));
    await repository.save(
      Encounter(
        id: 'enc-1',
        campaignId: 'campaign-1',
        name: 'Ruins ambush',
        status: EncounterStatus.closed,
        participants: <EncounterParticipant>[
          EncounterParticipant(
            entityType: 'character',
            entityId: 'pc-1',
            label: 'Aldren',
          ),
          EncounterParticipant(
            entityType: 'npc',
            entityId: 'npc-1',
            label: 'Bandit',
          ),
        ],
        notes: 'Resolved without combat rules.',
        createdAt: createdAt,
        updatedAt: closedAt,
        startedAt: startedAt,
        closedAt: closedAt,
      ),
    );
    repository.close();

    final reopened = SqliteEncounterRepository.open(path);
    final encounter = await reopened.getById('enc-1');
    expect(encounter, isNotNull);
    expect(encounter!.status, EncounterStatus.closed);
    expect(encounter.participants, hasLength(2));
    expect(encounter.participants.first.label, 'Aldren');
    expect(encounter.startedAt, startedAt);
    expect(encounter.closedAt, closedAt);
    expect(encounter.notes, 'Resolved without combat rules.');
    reopened.close();
  });

  test('save replaces participant aggregate atomically', () async {
    final temp = await Directory.systemTemp.createTemp('rolemaster-encounter-');
    final path = '${temp.path}/encounter.sqlite';
    addTearDown(() async => temp.delete(recursive: true));

    final campaignRepository = SqliteCampaignRepository.open(path);
    await campaignRepository.save(
      Campaign(
        id: 'campaign-1',
        name: 'Campaign',
        createdAt: DateTime.utc(2026, 8, 10, 21),
      ),
    );
    campaignRepository.close();

    final repository = SqliteEncounterRepository.open(path);
    final createdAt = DateTime.utc(2026, 8, 10, 21, 10);
    var encounter = Encounter(
      id: 'enc-1',
      campaignId: 'campaign-1',
      name: 'Road',
      participants: <EncounterParticipant>[
        EncounterParticipant(entityType: 'character', entityId: 'pc-1'),
        EncounterParticipant(entityType: 'npc', entityId: 'npc-1'),
      ],
      createdAt: createdAt,
    );
    await repository.save(encounter);

    encounter = encounter.removeParticipant(
      entityType: 'npc',
      entityId: 'npc-1',
      at: createdAt.add(const Duration(minutes: 1)),
    );
    await repository.save(encounter);

    final loaded = await repository.getById('enc-1');
    expect(loaded!.participants.map((item) => item.entityId), <String>['pc-1']);
    repository.close();
  });

  test('getForCampaign filters encounters by status', () async {
    final temp = await Directory.systemTemp.createTemp('rolemaster-encounter-');
    final path = '${temp.path}/encounter.sqlite';
    addTearDown(() async => temp.delete(recursive: true));

    final campaignRepository = SqliteCampaignRepository.open(path);
    await campaignRepository.save(
      Campaign(
        id: 'campaign-1',
        name: 'Campaign',
        createdAt: DateTime.utc(2026, 8, 10, 21),
      ),
    );
    campaignRepository.close();

    final repository = SqliteEncounterRepository.open(path);
    final createdAt = DateTime.utc(2026, 8, 10, 21, 10);
    await repository.save(
      Encounter(
        id: 'planned',
        campaignId: 'campaign-1',
        name: 'Planned',
        createdAt: createdAt,
      ),
    );
    await repository.save(
      Encounter(
        id: 'active',
        campaignId: 'campaign-1',
        name: 'Active',
        status: EncounterStatus.active,
        createdAt: createdAt,
        updatedAt: createdAt.add(const Duration(minutes: 1)),
        startedAt: createdAt.add(const Duration(minutes: 1)),
      ),
    );

    final active = await repository.getForCampaign(
      'campaign-1',
      status: EncounterStatus.active,
    );
    expect(active.map((item) => item.id), <String>['active']);
    repository.close();
  });

  test('migration v13 to v14 preserves scene map data', () async {
    final temp = await Directory.systemTemp.createTemp('rolemaster-encounter-');
    final path = '${temp.path}/encounter.sqlite';
    addTearDown(() async => temp.delete(recursive: true));

    final campaignRepository = SqliteCampaignRepository.open(path);
    await campaignRepository.save(
      Campaign(
        id: 'campaign-1',
        name: 'Campaign',
        createdAt: DateTime.utc(2026, 8, 10, 21),
      ),
    );
    campaignRepository.close();

    final mapRepository = SqliteSceneMapRepository.open(path);
    await mapRepository.saveMap(
      SceneMap(
        id: 'map-1',
        campaignId: 'campaign-1',
        name: 'Map',
        coordinateSpace: SceneCoordinateSpace(width: 80, height: 60),
        createdAt: DateTime.utc(2026, 8, 10, 21, 5),
      ),
    );
    mapRepository.close();

    final database = sqlite3.open(path);
    database.execute('DROP TABLE encounter_participants');
    database.execute('DROP TABLE encounters');
    database.execute('PRAGMA user_version = 13');
    database.close();

    final encounterRepository = SqliteEncounterRepository.open(path);
    expect(SqliteEncounterRepository.schemaVersion, 14);
    encounterRepository.close();

    final reopenedMapRepository = SqliteSceneMapRepository.open(path);
    final map = await reopenedMapRepository.getMapById('map-1');
    expect(map, isNotNull);
    expect(map!.name, 'Map');
    reopenedMapRepository.close();
  });
}

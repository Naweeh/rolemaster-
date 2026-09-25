import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('combat state and full action trace survive database reopen', () async {
    final temp = await Directory.systemTemp.createTemp('rolemaster-combat-');
    final path = '${temp.path}/combat.sqlite';
    addTearDown(() async => temp.delete(recursive: true));
    await _seedEncounter(path);

    var repository = SqliteCombatStateRepository.open(path);
    final initial = _state();
    await repository.save(initial);
    var updated = initial.addAction(
      CombatAction(actorKey: 'character:hero-1', result: _result()),
    );
    await repository.save(updated);
    updated = updated.advanceTurn();
    await repository.save(updated);
    repository.close();

    repository = SqliteCombatStateRepository.open(path);
    final loaded = await repository.getByEncounterId('enc-1');
    expect(loaded, isNotNull);
    expect(loaded!.revision, 2);
    expect(loaded.round, 1);
    expect(loaded.turnIndex, 1);
    expect(loaded.currentParticipant.key, 'npc:guide-1');
    expect(loaded.rulesetId, 'system-1');
    expect(loaded.rulesetVersion, '1');
    expect(loaded.actions.single.result.outcome, 'hit');
    expect(loaded.actions.single.result.details['damage'], 4);
    expect(loaded.actions.single.result.diceRolls.single.rolls, <int>[4]);
    expect(loaded.actions.single.result.diceRolls.single.total, 6);
    expect(await repository.getByEncounterId('missing'), isNull);
    repository.close();
  });

  test('rejects stale revisions and duplicate initial snapshots', () async {
    final temp = await Directory.systemTemp.createTemp('rolemaster-combat-');
    final path = '${temp.path}/combat.sqlite';
    addTearDown(() async => temp.delete(recursive: true));
    await _seedEncounter(path);
    final repository = SqliteCombatStateRepository.open(path);

    final initial = _state();
    await repository.save(initial);
    await expectLater(repository.save(initial), throwsStateError);

    final first = initial.advanceTurn();
    await repository.save(first);
    final stale = initial.addAction(
      CombatAction(actorKey: 'character:hero-1', result: _result()),
    );
    await expectLater(repository.save(stale), throwsStateError);
    final current = await repository.getByEncounterId('enc-1');
    expect(current!.revision, 1);
    expect(current.actions, isEmpty);
    expect(current.turnIndex, 1);
    repository.close();
  });

  test('rejects encounter participant changes and closure', () async {
    final temp = await Directory.systemTemp.createTemp('rolemaster-combat-');
    final path = '${temp.path}/combat.sqlite';
    addTearDown(() async => temp.delete(recursive: true));
    await _seedEncounter(path);
    final combat = SqliteCombatStateRepository.open(path);
    await combat.save(_state());

    final encounters = SqliteEncounterRepository.open(path);
    final stored = (await encounters.getById('enc-1'))!;
    await encounters.save(stored.removeParticipant(
      entityType: 'npc',
      entityId: 'guide-1',
      at: DateTime.utc(2026, 9, 25, 12),
    ));
    await expectLater(combat.save(_state().advanceTurn()), throwsStateError);
    await encounters.save(
      (await encounters.getById('enc-1'))!.close(
        at: DateTime.utc(2026, 9, 25, 13),
      ),
    );
    await expectLater(combat.save(_state().advanceTurn()), throwsStateError);
    expect((await combat.getByEncounterId('enc-1'))!.revision, 0);
    encounters.close();
    combat.close();
  });

  test('migration v14 to v15 preserves existing encounters', () async {
    final temp = await Directory.systemTemp.createTemp('rolemaster-combat-');
    final path = '${temp.path}/combat.sqlite';
    addTearDown(() async => temp.delete(recursive: true));
    await _seedEncounter(path);
    final database = sqlite3.open(path);
    database.execute('DROP TABLE combat_states');
    database.execute('PRAGMA user_version = 14');
    database.close();

    final combat = SqliteCombatStateRepository.open(path);
    expect(SqliteCombatStateRepository.schemaVersion, 15);
    expect(await combat.getByEncounterId('enc-1'), isNull);
    await combat.save(_state());
    combat.close();

    final encounters = SqliteEncounterRepository.open(path);
    expect((await encounters.getById('enc-1'))!.participants, hasLength(2));
    encounters.close();
  });
}

Future<void> _seedEncounter(String path) async {
  final campaigns = SqliteCampaignRepository.open(path);
  await campaigns.save(Campaign(
    id: 'campaign-1',
    name: 'Campaign',
    createdAt: DateTime.utc(2026, 9, 25, 10),
  ));
  campaigns.close();
  final encounters = SqliteEncounterRepository.open(path);
  await encounters.save(Encounter(
    id: 'enc-1',
    campaignId: 'campaign-1',
    name: 'Road fight',
    status: EncounterStatus.active,
    participants: <EncounterParticipant>[
      EncounterParticipant(entityType: 'character', entityId: 'hero-1'),
      EncounterParticipant(entityType: 'npc', entityId: 'guide-1'),
    ],
    createdAt: DateTime.utc(2026, 9, 25, 10),
    startedAt: DateTime.utc(2026, 9, 25, 11),
  ));
  encounters.close();
}

CombatState _state() {
  return CombatState(
    encounterId: 'enc-1',
    campaignId: 'campaign-1',
    rulesetId: 'system-1',
    rulesetVersion: '1',
    turnOrder: <CombatParticipant>[
      CombatParticipant(
        entityType: 'character',
        entityId: 'hero-1',
        name: 'Hero',
      ),
      CombatParticipant(entityType: 'npc', entityId: 'guide-1', name: 'Guide'),
    ],
  );
}

ResolutionResult _result() {
  final at = DateTime.utc(2026, 9, 25, 11, 1);
  return ResolutionResult(
    id: 'resolution-1',
    campaignId: 'campaign-1',
    rulesetId: 'system-1',
    rulesetVersion: '1',
    ruleId: 'attack',
    ruleKind: 'dice-threshold',
    outcome: 'hit',
    details: const <String, Object?>{'damage': 4},
    diceRolls: <DiceRollResult>[
      DiceRollResult(
        id: 'roll-1',
        campaignId: 'campaign-1',
        rulesetId: 'system-1',
        rulesetVersion: '1',
        formula: DiceFormula(count: 1, sides: 6, modifier: 2),
        rolls: <int>[4],
        occurredAt: at,
      ),
    ],
    occurredAt: at,
  );
}

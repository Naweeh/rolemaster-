import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  final at = DateTime.utc(2026, 9, 25);

  test('resolves three entity types and preserves explicit turn order', () async {
    final engine = _combatEngine();
    final state = await engine.start(
      encounter: _encounter(at),
      ruleset: _ruleset(),
      turnOrder: <String>['CREATURE:monster-1', 'character:hero-1', 'npc:guide-1'],
    );

    expect(state.encounterId, 'enc-1');
    expect(state.turnOrder.map((item) => item.name),
        <String>['Wolf', 'Hero', 'Guide']);
    expect(state.currentParticipant.key, 'creature:monster-1');
    expect(state.round, 1);
    expect(state.advanceTurn().currentParticipant.key, 'character:hero-1');
    final next = state.advanceTurn().advanceTurn().advanceTurn();
    expect(next.round, 2);
    expect(next.turnIndex, 0);
    expect(state.round, 1);
  });

  test('rejects missing, archived, foreign or unsupported participants',
      () async {
    final resolver = _resolver();
    for (final reference in <EncounterParticipant>[
      EncounterParticipant(entityType: 'npc', entityId: 'missing'),
      EncounterParticipant(entityType: 'character', entityId: 'archived'),
      EncounterParticipant(entityType: 'creature', entityId: 'foreign'),
      EncounterParticipant(entityType: 'vehicle', entityId: 'car'),
    ]) {
      final encounter = _encounter(at, participants: <EncounterParticipant>[reference]);
      await expectLater(resolver.resolve(encounter), throwsStateError);
    }
  });

  test('requires an active encounter and complete unique turn order',
      () async {
    final engine = _combatEngine();
    await expectLater(
      engine.start(
        encounter: Encounter(
          id: 'enc-1',
          campaignId: 'campaign-1',
          name: 'Pending',
          createdAt: at,
        ),
        ruleset: _ruleset(),
        turnOrder: <String>['character:hero-1'],
      ),
      throwsStateError,
    );
    await expectLater(
      engine.start(
        encounter: _encounter(at),
        ruleset: _ruleset(),
        turnOrder: <String>['character:hero-1', 'character:hero-1'],
      ),
      throwsArgumentError,
    );
    await expectLater(
      engine.start(
        encounter: _encounter(at),
        ruleset: _ruleset(campaignId: 'campaign-2'),
        turnOrder: <String>['character:hero-1'],
      ),
      throwsStateError,
    );
  });

  test('actions use Resolution Engine and never infer system-specific damage',
      () async {
    final engine = _combatEngine();
    final encounter = _encounter(at);
    final ruleset = _ruleset();
    final state = await engine.start(
      encounter: encounter,
      ruleset: ruleset,
      turnOrder: <String>[
        'character:hero-1',
        'npc:guide-1',
        'creature:monster-1',
      ],
    );
    final updated = engine.resolveAction(
      encounter: encounter,
      ruleset: ruleset,
      state: state,
      actorKey: 'CHARACTER:hero-1',
      request: ResolutionRequest(
        ruleId: 'strike',
        inputs: const <String, Object?>{'roll': 15},
      ),
    );

    expect(updated.actions.single.actorKey, 'character:hero-1');
    expect(updated.actions.single.result.outcome, 'hit');
    expect(updated.actions.single.result.details['result'],
        <String, Object?>{'outcome': 'hit'});
    expect(updated.actions.single.result.diceRolls, isEmpty);
    expect(state.actions, isEmpty);
    expect(
      () => engine.resolveAction(
        encounter: encounter,
        ruleset: ruleset,
        state: updated,
        actorKey: 'npc:guide-1',
        request: ResolutionRequest(ruleId: 'strike'),
      ),
      throwsStateError,
    );
    expect(
      () => engine.resolveAction(
        encounter: encounter.close(at: at.add(const Duration(minutes: 2))),
        ruleset: ruleset,
        state: state,
        actorKey: 'character:hero-1',
        request: ResolutionRequest(ruleId: 'strike'),
      ),
      throwsStateError,
    );
  });

  test('rejects participant changes during a combat session', () async {
    final engine = _combatEngine();
    final encounter = _encounter(at);
    final state = await engine.start(
      encounter: encounter,
      ruleset: _ruleset(),
      turnOrder: <String>[
        'character:hero-1',
        'npc:guide-1',
        'creature:monster-1',
      ],
    );
    final changed = encounter.removeParticipant(
      entityType: 'npc',
      entityId: 'guide-1',
      at: at.add(const Duration(minutes: 2)),
    );
    expect(
      () => engine.resolveAction(
        encounter: changed,
        ruleset: _ruleset(),
        state: state,
        actorKey: 'character:hero-1',
        request: ResolutionRequest(ruleId: 'strike'),
      ),
      throwsStateError,
    );
  });
}

Encounter _encounter(DateTime at, {
  Iterable<EncounterParticipant>? participants,
}) {
  return Encounter(
    id: 'enc-1',
    campaignId: 'campaign-1',
    name: 'Road fight',
    status: EncounterStatus.active,
    participants: participants ?? <EncounterParticipant>[
      EncounterParticipant(entityType: 'character', entityId: 'hero-1'),
      EncounterParticipant(entityType: 'npc', entityId: 'guide-1'),
      EncounterParticipant(entityType: 'creature', entityId: 'monster-1'),
    ],
    createdAt: at,
    startedAt: at.add(const Duration(minutes: 1)),
  );
}

CombatParticipantResolver _resolver() {
  final at = DateTime.utc(2026, 9, 25);
  return CombatParticipantResolver(
    characters: _CharacterRepo(<Character>[
      Character(id: 'hero-1', campaignId: 'campaign-1', name: 'Hero', createdAt: at),
      Character(
        id: 'archived',
        campaignId: 'campaign-1',
        name: 'Retired',
        createdAt: at,
        archivedAt: at,
      ),
    ]),
    npcs: _NpcRepo(<Npc>[
      Npc(
        id: 'guide-1',
        campaignId: 'campaign-1',
        name: 'Guide',
        createdAt: at,
        metadata: NpcMetadata(nativeLanguage: 'Common'),
      ),
    ]),
    creatures: _CreatureRepo(<Creature>[
      Creature(
        id: 'monster-1',
        campaignId: 'campaign-1',
        name: 'Wolf',
        createdAt: at,
        metadata: CreatureMetadata(species: 'Wolf'),
      ),
      Creature(
        id: 'foreign',
        campaignId: 'campaign-2',
        name: 'Foreign',
        createdAt: at,
        metadata: CreatureMetadata(species: 'Wolf'),
      ),
    ]),
  );
}

CombatEngine _combatEngine() {
  return CombatEngine(
    participantResolver: _resolver(),
    resolutionEngine: ResolutionEngine(
      diceEngine: DiceEngine(
        randomSource: _NoRandom(),
        idGenerator: () => 'dice-1',
        clock: () => DateTime.utc(2026, 9, 25),
      ),
      interpreters: <ResolutionRuleInterpreter>[
        TableLookupResolutionInterpreter(),
      ],
      idGenerator: () => 'resolution-1',
      clock: () => DateTime.utc(2026, 9, 25),
    ),
  );
}

EffectiveRuleset _ruleset({String campaignId = 'campaign-1'}) {
  return EffectiveRuleset(
    campaignId: campaignId,
    package: RulesetPackage(
      manifest: RulesetManifest(
        id: 'system-1',
        systemId: 'system',
        edition: 'Edition',
        version: '1',
        displayName: 'System',
      ),
      data: const <String, Object?>{
        'resolutionRules': <Object?>[
          <String, Object?>{
            'id': 'strike',
            'kind': 'table-lookup',
            'config': <String, Object?>{
              'tableId': 'attack',
              'inputKey': 'roll',
            },
          },
        ],
        'tables': <Object?>[
          <String, Object?>{
            'id': 'attack',
            'entries': <Object?>[
              <String, Object?>{
                'min': 1,
                'max': 10,
                'result': <String, Object?>{'outcome': 'miss'},
              },
              <String, Object?>{
                'min': 11,
                'max': 20,
                'result': <String, Object?>{'outcome': 'hit'},
              },
            ],
          },
        ],
      },
    ),
    activeModuleIds: const <String>[],
    overlay: CampaignRulesOverlay.clean(
      campaignId: campaignId,
      updatedAt: DateTime.utc(2026, 9, 25),
    ),
  );
}

final class _CharacterRepo implements CharacterRepository {
  _CharacterRepo(Iterable<Character> items)
      : _items = <String, Character>{for (final item in items) item.id: item};
  final Map<String, Character> _items;

  @override
  Future<Character?> getById(String id) async => _items[id];

  @override
  Future<List<Character>> getForCampaign(
    String campaignId, {
    bool includeArchived = false,
  }) async => _items.values.where((item) =>
      item.campaignId == campaignId && (includeArchived || !item.isArchived)).toList();

  @override
  Future<void> save(Character character) async {
    _items[character.id] = character;
  }
}

final class _NpcRepo implements NpcRepository {
  _NpcRepo(Iterable<Npc> items)
      : _items = <String, Npc>{for (final item in items) item.id: item};
  final Map<String, Npc> _items;

  @override
  Future<Npc?> getById(String id) async => _items[id];

  @override
  Future<List<Npc>> getForCampaign(
    String campaignId, {
    bool includeArchived = false,
  }) async => _items.values.where((item) =>
      item.campaignId == campaignId && (includeArchived || !item.isArchived)).toList();

  @override
  Future<void> save(Npc npc) async {
    _items[npc.id] = npc;
  }
}

final class _CreatureRepo implements CreatureRepository {
  _CreatureRepo(Iterable<Creature> items)
      : _items = <String, Creature>{for (final item in items) item.id: item};
  final Map<String, Creature> _items;

  @override
  Future<Creature?> getById(String id) async => _items[id];

  @override
  Future<List<Creature>> getForCampaign(
    String campaignId, {
    bool includeArchived = false,
  }) async => _items.values.where((item) =>
      item.campaignId == campaignId && (includeArchived || !item.isArchived)).toList();

  @override
  Future<void> save(Creature creature) async {
    _items[creature.id] = creature;
  }
}

final class _NoRandom implements DiceRandomSource {
  @override
  int nextInt(int upperBoundExclusive) =>
      throw StateError('No dice required for table lookup.');
}

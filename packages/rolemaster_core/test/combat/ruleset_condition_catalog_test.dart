import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  test('conditions are defined by effective ruleset and module gated', () {
    final catalog = RulesetConditionCatalog(_ruleset());
    expect(catalog.requireActive('slowed').durationRounds, 2);
    expect(catalog.requireActive('marked').durationRounds, isNull);
    expect(() => catalog.requireActive('spellbound'), throwsStateError);
    expect(() => catalog.requireActive('missing'), throwsStateError);
    expect(RulesetConditionCatalog(_ruleset(conditions: <Object?>[]))
        .definitions, isEmpty);
  });

  test('round expiry, refresh and removal preserve prior state', () {
    final state = _state();
    final applied = state.applyCondition(CombatCondition(
      participantKey: 'character:hero',
      conditionId: 'slowed',
      remainingRounds: 2,
    ));
    expect(applied.revision, 1);
    expect(state.conditions, isEmpty);
    expect(applied.advanceTurn().conditions.single.remainingRounds, 2);
    final nextRound = applied.advanceTurn().advanceTurn();
    expect(nextRound.round, 2);
    expect(nextRound.conditions.single.remainingRounds, 1);
    expect(nextRound.advanceTurn().advanceTurn().conditions, isEmpty);

    final refreshed = nextRound.applyCondition(CombatCondition(
      participantKey: 'character:hero',
      conditionId: 'slowed',
      remainingRounds: 3,
    ));
    expect(refreshed.conditions, hasLength(1));
    expect(refreshed.conditions.single.remainingRounds, 3);
    final removed = refreshed.removeCondition(
      participantKey: 'CHARACTER:hero',
      conditionId: 'slowed',
    );
    expect(removed.conditions, isEmpty);
    expect(() => removed.removeCondition(
      participantKey: 'character:hero',
      conditionId: 'slowed',
    ), throwsStateError);
  });

  test('persistent conditions survive rounds and invalid references fail', () {
    final state = _state().applyCondition(CombatCondition(
      participantKey: 'npc:guide',
      conditionId: 'marked',
      sourceKey: 'character:hero',
    ));
    expect(state.advanceTurn().advanceTurn().conditions.single.remainingRounds,
        isNull);
    expect(
      () => _state().applyCondition(CombatCondition(
        participantKey: 'npc:unknown',
        conditionId: 'marked',
      )),
      throwsArgumentError,
    );
    expect(
      () => _state().applyCondition(CombatCondition(
        participantKey: 'npc:guide',
        conditionId: 'marked',
        remainingRounds: 0,
      )),
      throwsArgumentError,
    );
  });

  test('catalog rejects duplicates and invalid module or duration', () {
    expect(
      () => RulesetConditionCatalog(_ruleset(conditions: <Object?>[
        <String, Object?>{'id': 'a'},
        <String, Object?>{'id': 'a'},
      ])).definitions,
      throwsStateError,
    );
    expect(
      () => RulesetConditionCatalog(_ruleset(conditions: <Object?>[
        <String, Object?>{'id': 'bad', 'moduleId': 'unknown'},
      ])).definitions,
      throwsStateError,
    );
    expect(
      () => RulesetConditionCatalog(_ruleset(conditions: <Object?>[
        <String, Object?>{'id': 'bad', 'durationRounds': 0},
      ])).definitions,
      throwsArgumentError,
    );
  });
}

CombatState _state() => CombatState(
  encounterId: 'enc-1',
  campaignId: 'campaign-1',
  rulesetId: 'ruleset-1',
  rulesetVersion: '1',
  turnOrder: <CombatParticipant>[
    CombatParticipant(
      entityType: 'character',
      entityId: 'hero',
      name: 'Hero',
    ),
    CombatParticipant(entityType: 'npc', entityId: 'guide', name: 'Guide'),
  ],
);

EffectiveRuleset _ruleset({List<Object?>? conditions}) {
  return EffectiveRuleset(
    campaignId: 'campaign-1',
    package: RulesetPackage(
      manifest: RulesetManifest(
        id: 'ruleset-1',
        systemId: 'system',
        edition: 'Edition',
        version: '1',
        displayName: 'System',
        modules: <RulesetModuleDefinition>[
          RulesetModuleDefinition(id: 'magic', name: 'Magic'),
        ],
      ),
      data: <String, Object?>{
        'conditions': conditions ?? <Object?>[
          <String, Object?>{'id': 'slowed', 'durationRounds': 2},
          <String, Object?>{'id': 'marked'},
          <String, Object?>{'id': 'spellbound', 'moduleId': 'magic'},
        ],
      },
    ),
    activeModuleIds: const <String>[],
    overlay: CampaignRulesOverlay.clean(
      campaignId: 'campaign-1',
      updatedAt: DateTime.utc(2026, 9, 25),
    ),
  );
}

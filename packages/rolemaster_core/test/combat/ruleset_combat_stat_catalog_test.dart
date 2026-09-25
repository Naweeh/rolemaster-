import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  test('two rulesets define different combat stats and initial values', () {
    final vitality = _ruleset(<Object?>[
      <String, Object?>{
        'id': 'vitality',
        'min': 0,
        'max': 30,
        'initial': 20,
      },
    ]);
    final guard = _ruleset(<Object?>[
      <String, Object?>{
        'id': 'guard',
        'min': -5,
        'max': 10,
        'initial': 2,
      },
    ]);

    expect(RulesetCombatStatCatalog(vitality).activeDefinitions.single.id,
        'vitality');
    expect(RulesetCombatStatCatalog(guard).activeDefinitions.single.id, 'guard');
    expect(RulesetCombatStatCatalog(guard).requireActive('guard').accepts(-5),
        isTrue);
    expect(RulesetCombatStatCatalog(guard).requireActive('guard').accepts(11),
        isFalse);
    expect(RulesetCombatStatCatalog(_ruleset(<Object?>[])).definitions, isEmpty);
  });

  test('rejects malformed definitions, duplicate IDs and inactive modules',
      () {
    expect(
      () => RulesetCombatStatCatalog(_ruleset(<Object?>[
        <String, Object?>{'id': 'hp', 'initial': 'ten'},
      ])).definitions,
      throwsStateError,
    );
    expect(
      () => RulesetCombatStatCatalog(_ruleset(<Object?>[
        <String, Object?>{'id': 'hp', 'min': 0, 'max': 10},
        <String, Object?>{'id': 'hp'},
      ])).definitions,
      throwsStateError,
    );
    expect(
      () => RulesetCombatStatCatalog(_ruleset(<Object?>[
        <String, Object?>{'id': 'hp', 'moduleId': 'magic'},
      ])).requireActive('hp'),
      throwsStateError,
    );
  });

  test('combat state stores and freezes ruleset-defined participant values',
      () {
    final stats = <String, Map<String, int>>{
      'character:hero': <String, int>{'vitality': 20},
    };
    final state = CombatState(
      encounterId: 'enc-1',
      campaignId: 'campaign-1',
      rulesetId: 'system',
      rulesetVersion: '1',
      turnOrder: <CombatParticipant>[
        CombatParticipant(
            entityType: 'character', entityId: 'hero', name: 'Hero'),
      ],
      stats: stats,
    );
    stats['character:hero']!['vitality'] = 0;
    expect(state.stats['character:hero']!['vitality'], 20);
    expect(() => state.stats['character:hero']!['vitality'] = 3,
        throwsUnsupportedError);
    final updated = state.setStat(
      participantKey: 'CHARACTER:hero',
      statId: 'vitality',
      value: 7,
    );
    expect(updated.revision, 1);
    expect(updated.stats['character:hero']!['vitality'], 7);
    expect(state.stats['character:hero']!['vitality'], 20);
  });
}

EffectiveRuleset _ruleset(List<Object?> stats) {
  return EffectiveRuleset(
    campaignId: 'campaign-1',
    package: RulesetPackage(
      manifest: RulesetManifest(
        id: 'system',
        systemId: 'system',
        edition: 'Edition',
        version: '1',
        displayName: 'System',
        modules: <RulesetModuleDefinition>[
          RulesetModuleDefinition(id: 'magic', name: 'Magic'),
        ],
      ),
      data: <String, Object?>{'combatStats': stats},
    ),
    activeModuleIds: const <String>[],
    overlay: CampaignRulesOverlay.clean(
      campaignId: 'campaign-1',
      updatedAt: DateTime.utc(2026, 9, 25),
    ),
  );
}

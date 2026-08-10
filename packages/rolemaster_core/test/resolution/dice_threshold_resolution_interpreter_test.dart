import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'threshold interpreter reads dice, modifier and target from ruleset/request',
      () {
    final ruleset = _ruleset(
      rule: const <String, Object?>{
        'id': 'skill-check',
        'kind': 'dice-threshold',
        'moduleId': 'core',
        'config': <String, Object?>{
          'dice': <String, Object?>{
            'count': 1,
            'sides': 20,
            'modifier': 2,
          },
          'modifierInput': 'skillBonus',
          'targetInput': 'difficulty',
          'successOutcome': 'passed',
          'failureOutcome': 'failed',
        },
      },
    );
    final engine = _engine(<int>[9]);

    final result = engine.resolve(
      ruleset: ruleset,
      request: ResolutionRequest(
        ruleId: 'skill-check',
        inputs: const <String, Object?>{
          'skillBonus': 3,
          'difficulty': 14,
        },
      ),
    );

    expect(result.outcome, 'passed');
    expect(result.diceRolls.single.rolls, <int>[10]);
    expect(result.diceRolls.single.formula.modifier, 5);
    expect(result.details['target'], 14);
    expect(result.details['total'], 15);
  });

  test('threshold interpreter uses configured target and default outcomes', () {
    final ruleset = _ruleset(
      rule: const <String, Object?>{
        'id': 'simple-check',
        'kind': 'dice-threshold',
        'config': <String, Object?>{
          'dice': <String, Object?>{'count': 2, 'sides': 6},
          'target': 10,
        },
      },
    );
    final engine = _engine(<int>[2, 3]);

    final result = engine.resolve(
      ruleset: ruleset,
      request: ResolutionRequest(ruleId: 'simple-check'),
    );

    expect(result.outcome, 'failure');
    expect(result.diceRolls.single.rolls, <int>[3, 4]);
    expect(result.details['total'], 7);
  });

  test('threshold interpreter rejects malformed ruleset configuration', () {
    final ruleset = _ruleset(
      rule: const <String, Object?>{
        'id': 'bad-check',
        'kind': 'dice-threshold',
        'config': <String, Object?>{
          'dice': <String, Object?>{'count': 1, 'sides': 'd20'},
          'target': 10,
        },
      },
    );

    expect(
      () => _engine(<int>[0]).resolve(
        ruleset: ruleset,
        request: ResolutionRequest(ruleId: 'bad-check'),
      ),
      throwsStateError,
    );
  });
}

ResolutionEngine _engine(Iterable<int> randomValues) {
  final source = _SequenceRandomSource(randomValues);
  return ResolutionEngine(
    diceEngine: DiceEngine(
      randomSource: source,
      idGenerator: () => 'dice-${source.index}',
      clock: () => DateTime.utc(2026, 8, 10, 22, 30),
    ),
    interpreters: <ResolutionRuleInterpreter>[
      DiceThresholdResolutionInterpreter(),
    ],
    idGenerator: () => 'resolution-1',
    clock: () => DateTime.utc(2026, 8, 10, 22, 31),
  );
}

EffectiveRuleset _ruleset({required Map<String, Object?> rule}) {
  final package = RulesetPackage(
    manifest: RulesetManifest(
      id: 'ruleset-1',
      systemId: 'system-1',
      edition: 'Edition',
      version: '1.0.0',
      displayName: 'Ruleset',
      modules: <RulesetModuleDefinition>[
        RulesetModuleDefinition(id: 'core', name: 'Core', required: true),
      ],
    ),
    data: <String, Object?>{
      'resolutionRules': <Object?>[rule],
    },
  );
  return EffectiveRuleset(
    campaignId: 'campaign-1',
    package: package,
    activeModuleIds: <String>['core'],
    overlay: CampaignRulesOverlay.clean(
      campaignId: 'campaign-1',
      updatedAt: DateTime.utc(2026, 8, 10, 22),
    ),
  );
}

final class _SequenceRandomSource implements DiceRandomSource {
  _SequenceRandomSource(Iterable<int> values) : _values = values.toList();

  final List<int> _values;
  var _index = 0;

  int get index => _index;

  @override
  int nextInt(int upperBoundExclusive) {
    if (_index >= _values.length) {
      throw StateError('No more deterministic random values.');
    }
    return _values[_index++];
  }
}

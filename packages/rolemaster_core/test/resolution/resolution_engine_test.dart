import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  test('catalog parses rules from effective ruleset', () {
    final catalog = RulesetResolutionCatalog(_ruleset());
    final definition = catalog.find('check');

    expect(definition, isNotNull);
    expect(definition!.kind, 'fake-check');
    expect(definition.moduleId, 'core');
    expect(definition.config['difficulty'], 12);
  });

  test('engine dispatches by kind and produces traceable result', () {
    final diceEngine = DiceEngine(
      randomSource: _SequenceRandomSource(<int>[4]),
      idGenerator: () => 'dice-1',
      clock: () => DateTime.utc(2026, 8, 10, 22, 20),
    );
    final engine = ResolutionEngine(
      diceEngine: diceEngine,
      interpreters: <ResolutionRuleInterpreter>[_FakeCheckInterpreter()],
      idGenerator: () => 'resolution-1',
      clock: () => DateTime.utc(2026, 8, 10, 22, 21),
    );

    final result = engine.resolve(
      ruleset: _ruleset(),
      request: ResolutionRequest(
        ruleId: 'check',
        purpose: 'demo',
        inputs: const <String, Object?>{'modifier': 8},
      ),
    );

    expect(result.id, 'resolution-1');
    expect(result.campaignId, 'campaign-1');
    expect(result.rulesetId, 'ruleset-1');
    expect(result.rulesetVersion, '1.0.0');
    expect(result.ruleId, 'check');
    expect(result.ruleKind, 'fake-check');
    expect(result.outcome, 'success');
    expect(result.details['total'], 13);
    expect(result.diceRolls.single.rolls, <int>[5]);
    expect(result.purpose, 'demo');
    expect(result.occurredAt, DateTime.utc(2026, 8, 10, 22, 21));
  });

  test('engine rejects a rule gated behind an inactive module', () {
    final engine = _engine();

    expect(
      () => engine.resolve(
        ruleset: _ruleset(activeModules: <String>['core']),
        request: ResolutionRequest(ruleId: 'magic-check'),
      ),
      throwsA(isA<ResolutionModuleInactiveException>()),
    );
  });

  test('engine rejects unknown rule and unknown interpreter kind', () {
    final engine = _engine();

    expect(
      () => engine.resolve(
        ruleset: _ruleset(),
        request: ResolutionRequest(ruleId: 'missing'),
      ),
      throwsA(isA<ResolutionRuleNotFoundException>()),
    );
    expect(
      () => engine.resolve(
        ruleset: _ruleset(activeModules: <String>['core', 'magic']),
        request: ResolutionRequest(ruleId: 'magic-check'),
      ),
      throwsA(isA<ResolutionInterpreterNotFoundException>()),
    );
  });

  test('engine rejects duplicate interpreter kinds', () {
    expect(
      () => ResolutionEngine(
        diceEngine: DiceEngine(
          randomSource: _SequenceRandomSource(<int>[0]),
          idGenerator: () => 'dice',
          clock: DateTime.now,
        ),
        interpreters: <ResolutionRuleInterpreter>[
          _FakeCheckInterpreter(),
          _FakeCheckInterpreter(),
        ],
        idGenerator: () => 'resolution',
        clock: DateTime.now,
      ),
      throwsA(isA<DuplicateResolutionInterpreterException>()),
    );
  });

  test('engine rejects dice trace from another ruleset', () {
    final foreignPackage = RulesetPackage(
      manifest: RulesetManifest(
        id: 'foreign',
        systemId: 'system',
        edition: 'Foreign',
        version: '1',
        displayName: 'Foreign',
      ),
    );
    final foreignRuleset = EffectiveRuleset(
      campaignId: 'foreign-campaign',
      package: foreignPackage,
      activeModuleIds: const <String>[],
      overlay: CampaignRulesOverlay.clean(
        campaignId: 'foreign-campaign',
        updatedAt: DateTime.utc(2026, 8, 10, 22),
      ),
    );
    final engine = ResolutionEngine(
      diceEngine: DiceEngine(
        randomSource: _SequenceRandomSource(<int>[0]),
        idGenerator: () => 'dice',
        clock: DateTime.now,
      ),
      interpreters: <ResolutionRuleInterpreter>[
        _ForeignRollInterpreter(foreignRuleset),
      ],
      idGenerator: () => 'resolution',
      clock: DateTime.now,
    );

    expect(
      () => engine.resolve(
        ruleset: _ruleset(),
        request: ResolutionRequest(ruleId: 'check'),
      ),
      throwsStateError,
    );
  });
}

ResolutionEngine _engine() {
  return ResolutionEngine(
    diceEngine: DiceEngine(
      randomSource: _SequenceRandomSource(<int>[0, 1, 2]),
      idGenerator: () => 'dice',
      clock: DateTime.now,
    ),
    interpreters: <ResolutionRuleInterpreter>[_FakeCheckInterpreter()],
    idGenerator: () => 'resolution',
    clock: DateTime.now,
  );
}

EffectiveRuleset _ruleset({
  Iterable<String> activeModules = const <String>['core'],
}) {
  final package = RulesetPackage(
    manifest: RulesetManifest(
      id: 'ruleset-1',
      systemId: 'system-1',
      edition: 'Edition',
      version: '1.0.0',
      displayName: 'Ruleset',
      modules: <RulesetModuleDefinition>[
        RulesetModuleDefinition(id: 'core', name: 'Core', required: true),
        RulesetModuleDefinition(id: 'magic', name: 'Magic'),
      ],
    ),
    data: const <String, Object?>{
      'resolutionRules': <Object?>[
        <String, Object?>{
          'id': 'check',
          'kind': 'fake-check',
          'moduleId': 'core',
          'config': <String, Object?>{'difficulty': 12},
        },
        <String, Object?>{
          'id': 'magic-check',
          'kind': 'missing-kind',
          'moduleId': 'magic',
          'config': <String, Object?>{},
        },
      ],
    },
  );
  return EffectiveRuleset(
    campaignId: 'campaign-1',
    package: package,
    activeModuleIds: activeModules,
    overlay: CampaignRulesOverlay.clean(
      campaignId: 'campaign-1',
      updatedAt: DateTime.utc(2026, 8, 10, 22),
    ),
  );
}

final class _FakeCheckInterpreter implements ResolutionRuleInterpreter {
  @override
  String get kind => 'fake-check';

  @override
  ResolutionEvaluation evaluate({
    required EffectiveRuleset ruleset,
    required ResolutionRuleDefinition definition,
    required ResolutionRequest request,
    required DiceEngine diceEngine,
  }) {
    final modifier = (request.inputs['modifier'] as int?) ?? 0;
    final difficulty = definition.config['difficulty']! as int;
    final roll = diceEngine.roll(
      ruleset: ruleset,
      formula: DiceFormula(count: 1, sides: 20, modifier: modifier),
      purpose: request.purpose,
    );
    return ResolutionEvaluation(
      outcome: roll.total >= difficulty ? 'success' : 'failure',
      details: <String, Object?>{
        'difficulty': difficulty,
        'total': roll.total,
      },
      diceRolls: <DiceRollResult>[roll],
    );
  }
}

final class _ForeignRollInterpreter implements ResolutionRuleInterpreter {
  _ForeignRollInterpreter(this.foreignRuleset);

  final EffectiveRuleset foreignRuleset;

  @override
  String get kind => 'fake-check';

  @override
  ResolutionEvaluation evaluate({
    required EffectiveRuleset ruleset,
    required ResolutionRuleDefinition definition,
    required ResolutionRequest request,
    required DiceEngine diceEngine,
  }) {
    final roll = diceEngine.roll(
      ruleset: foreignRuleset,
      formula: DiceFormula(count: 1, sides: 6),
    );
    return ResolutionEvaluation(
      outcome: 'invalid',
      diceRolls: <DiceRollResult>[roll],
    );
  }
}

final class _SequenceRandomSource implements DiceRandomSource {
  _SequenceRandomSource(Iterable<int> values) : _values = values.toList();

  final List<int> _values;
  var _index = 0;

  @override
  int nextInt(int upperBoundExclusive) {
    if (_index >= _values.length) {
      throw StateError('No more deterministic random values.');
    }
    return _values[_index++];
  }
}

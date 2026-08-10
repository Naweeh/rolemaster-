import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  test('DiceFormula validates shape and exposes notation', () {
    expect(DiceFormula(count: 2, sides: 6, modifier: 3).notation, '2d6+3');
    expect(DiceFormula(count: 1, sides: 20, modifier: -2).notation, '1d20-2');
    expect(DiceFormula(count: 3, sides: 6).notation, '3d6');
    expect(() => DiceFormula(count: 0, sides: 6), throwsArgumentError);
    expect(() => DiceFormula(count: 1, sides: 1), throwsArgumentError);
  });

  test('DiceEngine is deterministic with injected RNG and traces ruleset', () {
    final ruleset = _effectiveRuleset();
    final engine = DiceEngine(
      randomSource: _SequenceRandomSource(<int>[0, 3, 5]),
      idGenerator: () => 'roll-1',
      clock: () => DateTime.utc(2026, 8, 10, 22, 15),
    );

    final result = engine.roll(
      ruleset: ruleset,
      formula: DiceFormula(count: 3, sides: 6, modifier: 2),
      purpose: 'attribute-check',
    );

    expect(result.id, 'roll-1');
    expect(result.campaignId, 'campaign-1');
    expect(result.rulesetId, 'ruleset-1');
    expect(result.rulesetVersion, '1.0.0');
    expect(result.formula.notation, '3d6+2');
    expect(result.rolls, <int>[1, 4, 6]);
    expect(result.diceTotal, 11);
    expect(result.total, 13);
    expect(result.purpose, 'attribute-check');
    expect(result.occurredAt, DateTime.utc(2026, 8, 10, 22, 15));
    expect(() => result.rolls.add(2), throwsUnsupportedError);
  });

  test('DiceEngine rejects an invalid random source result', () {
    final engine = DiceEngine(
      randomSource: _SequenceRandomSource(<int>[6]),
      idGenerator: () => 'roll-1',
      clock: () => DateTime.utc(2026, 8, 10, 22, 15),
    );

    expect(
      () => engine.roll(
        ruleset: _effectiveRuleset(),
        formula: DiceFormula(count: 1, sides: 6),
      ),
      throwsStateError,
    );
  });

  test('DiceRollResult validates individual roll values', () {
    expect(
      () => DiceRollResult(
        id: 'roll-1',
        campaignId: 'campaign-1',
        rulesetId: 'ruleset-1',
        rulesetVersion: '1.0.0',
        formula: DiceFormula(count: 1, sides: 6),
        rolls: <int>[7],
        occurredAt: DateTime.utc(2026, 8, 10, 22),
      ),
      throwsArgumentError,
    );
  });
}

EffectiveRuleset _effectiveRuleset() {
  final package = RulesetPackage(
    manifest: RulesetManifest(
      id: 'ruleset-1',
      systemId: 'system-1',
      edition: 'Edition 1',
      version: '1.0.0',
      displayName: 'Ruleset One',
      modules: <RulesetModuleDefinition>[
        RulesetModuleDefinition(id: 'core', name: 'Core', required: true),
      ],
    ),
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

  @override
  int nextInt(int upperBoundExclusive) {
    if (_index >= _values.length) {
      throw StateError('No more deterministic random values.');
    }
    return _values[_index++];
  }
}

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  test('uses a request input and records the matching range and result', () {
    final result = _engine().resolve(
      ruleset: _ruleset(),
      request: ResolutionRequest(
        ruleId: 'lookup',
        purpose: 'critical hit',
        inputs: const <String, Object?>{'roll': 15},
      ),
    );

    expect(result.ruleKind, 'table-lookup');
    expect(result.outcome, 'critical');
    expect(result.details, <String, Object?>{
      'tableId': 'critical',
      'input': 15,
      'min': 11,
      'max': 20,
      'result': <String, Object?>{'outcome': 'critical', 'grade': 'B'},
    });
    expect(result.diceRolls, isEmpty);
    expect(result.campaignId, 'campaign-1');
    expect(result.rulesetVersion, '1.0.0');
    expect(result.purpose, 'critical hit');
  });

  test('accepts a fixed input and configurable matching outcome', () {
    final result = _engine().resolve(
      ruleset: _ruleset(
        config: const <String, Object?>{
          'tableId': 'critical',
          'input': 10,
          'matchOutcome': 'custom',
        },
      ),
      request: ResolutionRequest(ruleId: 'lookup'),
    );

    expect(result.outcome, 'custom');
    expect(result.details['min'], 1);
    expect(result.details['max'], 10);
  });

  test('returns an explicit outcome for a sparse table gap', () {
    final result = _engine().resolve(
      ruleset: _ruleset(
        config: const <String, Object?>{
          'tableId': 'critical',
          'input': 7,
          'noMatchOutcome': 'miss',
        },
      ),
      request: ResolutionRequest(ruleId: 'lookup'),
    );

    expect(result.outcome, 'miss');
    expect(result.details['result'], isNull);
    expect(result.details['min'], isNull);
    expect(result.details['max'], isNull);
  });

  test('requires explicit outcome when no range matches', () {
    expect(
      () => _engine().resolve(
        ruleset: _ruleset(
          config: const <String, Object?>{
            'tableId': 'critical',
            'input': 7,
          },
        ),
        request: ResolutionRequest(ruleId: 'lookup'),
      ),
      throwsStateError,
    );
  });

  test('propagates missing table and inactive module exceptions', () {
    expect(
      () => _engine().resolve(
        ruleset: _ruleset(
          config: const <String, Object?>{
            'tableId': 'missing',
            'input': 3,
          },
        ),
        request: ResolutionRequest(ruleId: 'lookup'),
      ),
      throwsA(isA<RulesetTableNotFoundException>()),
    );
    expect(
      () => _engine().resolve(
        ruleset: _ruleset(
          config: const <String, Object?>{
            'tableId': 'magic-table',
            'input': 3,
          },
        ),
        request: ResolutionRequest(ruleId: 'lookup'),
      ),
      throwsA(isA<RulesetTableModuleInactiveException>()),
    );
  });

  test('rejects missing or ambiguous lookup inputs', () {
    for (final config in <Map<String, Object?>>[
      <String, Object?>{'tableId': 'critical'},
      <String, Object?>{
        'tableId': 'critical',
        'input': 3,
        'inputKey': 'roll',
      },
      <String, Object?>{'tableId': 'critical', 'inputKey': 'roll'},
    ]) {
      expect(
        () => _engine().resolve(
          ruleset: _ruleset(config: config),
          request: ResolutionRequest(ruleId: 'lookup'),
        ),
        throwsStateError,
      );
    }
  });
}

ResolutionEngine _engine() {
  return ResolutionEngine(
    diceEngine: DiceEngine(
      randomSource: _UnusedRandomSource(),
      idGenerator: () => 'dice-1',
      clock: () => DateTime.utc(2026, 8, 10),
    ),
    interpreters: <ResolutionRuleInterpreter>[
      TableLookupResolutionInterpreter(),
    ],
    idGenerator: () => 'resolution-1',
    clock: () => DateTime.utc(2026, 8, 10),
  );
}

EffectiveRuleset _ruleset({
  Map<String, Object?> config = const <String, Object?>{
    'tableId': 'critical',
    'inputKey': 'roll',
  },
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
    data: <String, Object?>{
      'resolutionRules': <Object?>[
        <String, Object?>{
          'id': 'lookup',
          'kind': 'table-lookup',
          'config': config,
        },
      ],
      'tables': const <Object?>[
        <String, Object?>{
          'id': 'critical',
          'gapPolicy': 'sparse',
          'moduleId': 'core',
          'entries': <Object?>[
            <String, Object?>{
              'min': 1,
              'max': 5,
              'result': <String, Object?>{'grade': 'A'},
            },
            <String, Object?>{
              'min': 11,
              'max': 20,
              'result': <String, Object?>{
                'outcome': 'critical',
                'grade': 'B',
              },
            },
          ],
        },
        <String, Object?>{
          'id': 'magic-table',
          'moduleId': 'magic',
          'entries': <Object?>[
            <String, Object?>{'min': 1, 'max': 5},
          ],
        },
      ],
    },
  );
  return EffectiveRuleset(
    campaignId: 'campaign-1',
    package: package,
    activeModuleIds: <String>['core'],
    overlay: CampaignRulesOverlay.clean(
      campaignId: 'campaign-1',
      updatedAt: DateTime.utc(2026, 8, 10),
    ),
  );
}

final class _UnusedRandomSource implements DiceRandomSource {
  @override
  int nextInt(int upperBoundExclusive) {
    throw StateError('Table lookup must not roll dice.');
  }
}

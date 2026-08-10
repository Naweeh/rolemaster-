import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  test('contiguous table sorts ranges and performs inclusive lookup', () {
    final table = RulesetTableDefinition(
      id: 'critical',
      entries: <RulesetTableEntry>[
        RulesetTableEntry(min: 11, max: 20, result: const {'grade': 'B'}),
        RulesetTableEntry(min: 1, max: 10, result: const {'grade': 'A'}),
      ],
    );

    expect(table.entries.first.min, 1);
    expect(table.lookup(1)?.result['grade'], 'A');
    expect(table.lookup(10)?.result['grade'], 'A');
    expect(table.lookup(11)?.result['grade'], 'B');
    expect(table.lookup(20)?.result['grade'], 'B');
    expect(table.lookup(21), isNull);
  });

  test('contiguous policy rejects gaps and all policies reject overlap', () {
    expect(
      () => RulesetTableDefinition(
        id: 'gap',
        entries: <RulesetTableEntry>[
          RulesetTableEntry(min: 1, max: 5),
          RulesetTableEntry(min: 7, max: 10),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => RulesetTableDefinition(
        id: 'overlap',
        gapPolicy: RulesetTableGapPolicy.sparse,
        entries: <RulesetTableEntry>[
          RulesetTableEntry(min: 1, max: 5),
          RulesetTableEntry(min: 5, max: 10),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('sparse policy allows gaps and returns null inside them', () {
    final table = RulesetTableDefinition(
      id: 'sparse',
      gapPolicy: RulesetTableGapPolicy.sparse,
      entries: <RulesetTableEntry>[
        RulesetTableEntry(min: 1, max: 3),
        RulesetTableEntry(min: 8, max: 10),
      ],
    );

    expect(table.lookup(2), isNotNull);
    expect(table.lookup(5), isNull);
    expect(table.lookup(9), isNotNull);
  });

  test('catalog parses tables from EffectiveRuleset and enforces module gate', () {
    final ruleset = _ruleset(
      activeModules: <String>['core'],
      tables: const <Object?>[
        <String, Object?>{
          'id': 'core-table',
          'moduleId': 'core',
          'entries': <Object?>[
            <String, Object?>{
              'min': 1,
              'max': 10,
              'result': <String, Object?>{'value': 'core'},
            },
          ],
        },
        <String, Object?>{
          'id': 'magic-table',
          'moduleId': 'magic',
          'gapPolicy': 'sparse',
          'entries': <Object?>[
            <String, Object?>{
              'min': 1,
              'max': 5,
              'result': <String, Object?>{'value': 'magic'},
            },
          ],
        },
      ],
    );
    final catalog = RulesetTableCatalog(ruleset);

    expect(catalog.lookup(tableId: 'core-table', value: 4)?.result['value'], 'core');
    expect(
      () => catalog.lookup(tableId: 'magic-table', value: 2),
      throwsA(isA<RulesetTableModuleInactiveException>()),
    );
    expect(
      () => catalog.lookup(tableId: 'missing', value: 1),
      throwsA(isA<RulesetTableNotFoundException>()),
    );
  });

  test('overlay can replace table definitions without mutating base package', () {
    const baseTables = <Object?>[
      <String, Object?>{
        'id': 'table-1',
        'entries': <Object?>[
          <String, Object?>{
            'min': 1,
            'max': 10,
            'result': <String, Object?>{'value': 'base'},
          },
        ],
      },
    ];
    const overlayTables = <Object?>[
      <String, Object?>{
        'id': 'table-1',
        'entries': <Object?>[
          <String, Object?>{
            'min': 1,
            'max': 10,
            'result': <String, Object?>{'value': 'campaign'},
          },
        ],
      },
    ];
    final package = _package(baseTables);
    final effective = EffectiveRuleset(
      campaignId: 'campaign-1',
      package: package,
      activeModuleIds: <String>['core'],
      overlay: CampaignRulesOverlay(
        campaignId: 'campaign-1',
        updatedAt: DateTime.utc(2026, 8, 10, 22),
        overrides: const <String, Object?>{'tables': overlayTables},
      ),
    );

    expect(
      RulesetTableCatalog(effective)
          .lookup(tableId: 'table-1', value: 5)
          ?.result['value'],
      'campaign',
    );
    expect(
      ((package.data['tables']! as List).first as Map)['entries'],
      isNotEmpty,
    );
    expect(
      ((((package.data['tables']! as List).first as Map)['entries'] as List)
              .first as Map)['result']['value'],
      'base',
    );
  });
}

EffectiveRuleset _ruleset({
  required Iterable<String> activeModules,
  required List<Object?> tables,
}) {
  final package = _package(tables);
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

RulesetPackage _package(List<Object?> tables) {
  return RulesetPackage(
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
    data: <String, Object?>{'tables': tables},
  );
}

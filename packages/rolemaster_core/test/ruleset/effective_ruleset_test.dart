import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  test('resolves exact package, active modules and deep overlay', () async {
    final package = _package();
    final state = _state(
      campaignId: 'campaign-1',
      overrides: const <String, Object?>{
        'resolution': <String, Object?>{
          'critical': <String, Object?>{'enabled': false},
        },
        'tables': <Object?>['campaign-table'],
      },
    );
    final resolver = ResolveEffectiveRuleset(
      rulesetRepository: _RulesetRepo(<RulesetPackage>[package]),
      campaignRulesetRepository: _CampaignRulesetRepo(<CampaignRulesetState>[
        state,
      ]),
    );

    final effective = await resolver('campaign-1');

    expect(effective.rulesetId, 'ruleset-1');
    expect(effective.version, '1.0.0');
    expect(effective.activeModuleIds, <String>['core', 'combat']);
    expect(effective.isModuleActive('combat'), isTrue);

    final resolution = effective.data['resolution']! as Map<String, Object?>;
    expect(resolution['openEnded'], isTrue);
    final critical = resolution['critical']! as Map<String, Object?>;
    expect(critical['enabled'], isFalse);
    expect(critical['severity'], 5);
    expect(effective.data['tables'], <Object?>['campaign-table']);
  });

  test('overlay never mutates published package data', () async {
    final package = _package();
    final resolver = ResolveEffectiveRuleset(
      rulesetRepository: _RulesetRepo(<RulesetPackage>[package]),
      campaignRulesetRepository: _CampaignRulesetRepo(<CampaignRulesetState>[
        _state(
          campaignId: 'campaign-1',
          overrides: const <String, Object?>{
            'resolution': <String, Object?>{'openEnded': false},
          },
        ),
      ]),
    );

    final effective = await resolver('campaign-1');
    final effectiveResolution =
        effective.data['resolution']! as Map<String, Object?>;
    final packageResolution =
        package.data['resolution']! as Map<String, Object?>;

    expect(effectiveResolution['openEnded'], isFalse);
    expect(packageResolution['openEnded'], isTrue);
    expect(
      () => effectiveResolution['openEnded'] = true,
      throwsUnsupportedError,
    );
  });

  test('campaign overlays remain isolated while sharing a package', () async {
    final package = _package();
    final resolver = ResolveEffectiveRuleset(
      rulesetRepository: _RulesetRepo(<RulesetPackage>[package]),
      campaignRulesetRepository: _CampaignRulesetRepo(<CampaignRulesetState>[
        _state(
          campaignId: 'campaign-a',
          overrides: const <String, Object?>{
            'resolution': <String, Object?>{'openEnded': false},
          },
        ),
        _state(
          campaignId: 'campaign-b',
          overrides: const <String, Object?>{
            'resolution': <String, Object?>{'openEnded': true},
          },
        ),
      ]),
    );

    final a = await resolver('campaign-a');
    final b = await resolver('campaign-b');

    expect(
      (a.data['resolution']! as Map<String, Object?>)['openEnded'],
      isFalse,
    );
    expect(
      (b.data['resolution']! as Map<String, Object?>)['openEnded'],
      isTrue,
    );
    expect(
      (package.data['resolution']! as Map<String, Object?>)['openEnded'],
      isTrue,
    );
  });

  test('rejects unknown active module', () async {
    final resolver = ResolveEffectiveRuleset(
      rulesetRepository: _RulesetRepo(<RulesetPackage>[_package()]),
      campaignRulesetRepository: _CampaignRulesetRepo(<CampaignRulesetState>[
        _state(
          campaignId: 'campaign-1',
          activeModuleIds: <String>['core', 'unknown'],
        ),
      ]),
    );

    expect(
      () => resolver('campaign-1'),
      throwsA(isA<UnknownRulesetModuleException>()),
    );
  });

  test('rejects missing required module', () async {
    final resolver = ResolveEffectiveRuleset(
      rulesetRepository: _RulesetRepo(<RulesetPackage>[_package()]),
      campaignRulesetRepository: _CampaignRulesetRepo(<CampaignRulesetState>[
        _state(
          campaignId: 'campaign-1',
          activeModuleIds: <String>['combat'],
        ),
      ]),
    );

    expect(
      () => resolver('campaign-1'),
      throwsA(isA<RequiredRulesetModuleMissingException>()),
    );
  });

  test('rejects package returned with a different identity', () async {
    final wrong = RulesetPackage(
      manifest: RulesetManifest(
        id: 'wrong',
        systemId: 'system',
        edition: 'Edition',
        version: '9.9.9',
        displayName: 'Wrong',
      ),
    );
    final resolver = ResolveEffectiveRuleset(
      rulesetRepository: _RulesetRepo.force(wrong),
      campaignRulesetRepository: _CampaignRulesetRepo(<CampaignRulesetState>[
        _state(campaignId: 'campaign-1'),
      ]),
    );

    expect(
      () => resolver('campaign-1'),
      throwsA(isA<RulesetBindingMismatchException>()),
    );
  });

  test('requires a campaign ruleset binding', () async {
    final resolver = ResolveEffectiveRuleset(
      rulesetRepository: _RulesetRepo(<RulesetPackage>[_package()]),
      campaignRulesetRepository: _CampaignRulesetRepo(
        const <CampaignRulesetState>[],
      ),
    );

    expect(
      () => resolver('campaign-1'),
      throwsA(isA<CampaignRulesetNotInitializedException>()),
    );
  });
}

RulesetPackage _package() {
  return RulesetPackage(
    manifest: RulesetManifest(
      id: 'ruleset-1',
      systemId: 'system-1',
      edition: 'Edition 1',
      version: '1.0.0',
      displayName: 'Ruleset One',
      modules: <RulesetModuleDefinition>[
        RulesetModuleDefinition(id: 'core', name: 'Core', required: true),
        RulesetModuleDefinition(id: 'combat', name: 'Combat'),
        RulesetModuleDefinition(id: 'magic', name: 'Magic'),
      ],
    ),
    data: const <String, Object?>{
      'resolution': <String, Object?>{
        'openEnded': true,
        'critical': <String, Object?>{
          'enabled': true,
          'severity': 5,
        },
      },
      'tables': <Object?>['base-table'],
    },
  );
}

CampaignRulesetState _state({
  required String campaignId,
  Iterable<String> activeModuleIds = const <String>['core', 'combat'],
  Map<String, Object?> overrides = const <String, Object?>{},
}) {
  final at = DateTime.utc(2026, 8, 10, 22);
  return CampaignRulesetState(
    binding: CampaignRulesetBinding(
      campaignId: campaignId,
      rulesetId: 'ruleset-1',
      rulesetVersion: '1.0.0',
      activeModuleIds: activeModuleIds,
      boundAt: at,
    ),
    overlay: CampaignRulesOverlay(
      campaignId: campaignId,
      updatedAt: at,
      overrides: overrides,
    ),
  );
}

final class _RulesetRepo implements RulesetRepository {
  _RulesetRepo(Iterable<RulesetPackage> packages)
      : _packages = <String, RulesetPackage>{
          for (final package in packages)
            '${package.manifest.id}@${package.manifest.version}': package,
        },
        _forced = null;

  _RulesetRepo.force(RulesetPackage package)
      : _packages = const <String, RulesetPackage>{},
        _forced = package;

  final Map<String, RulesetPackage> _packages;
  final RulesetPackage? _forced;

  @override
  Future<RulesetPackage?> getPackage({
    required String rulesetId,
    required String version,
  }) async {
    return _forced ?? _packages['$rulesetId@$version'];
  }

  @override
  Future<List<RulesetPackage>> getAvailablePackages() async {
    return _packages.values.toList(growable: false);
  }
}

final class _CampaignRulesetRepo implements CampaignRulesetRepository {
  _CampaignRulesetRepo(Iterable<CampaignRulesetState> states)
      : _states = <String, CampaignRulesetState>{
          for (final state in states) state.binding.campaignId: state,
        };

  final Map<String, CampaignRulesetState> _states;

  @override
  Future<CampaignRulesetState?> getForCampaign(String campaignId) async {
    return _states[campaignId];
  }

  @override
  Future<void> save(CampaignRulesetState state) async {
    _states[state.binding.campaignId] = state;
  }
}

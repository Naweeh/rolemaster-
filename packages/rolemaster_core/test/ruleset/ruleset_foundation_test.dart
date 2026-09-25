import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  group('Ruleset Foundation', () {
    test('initializes a campaign with an exact version and clean overlay',
        () async {
      final campaigns = _MemoryCampaignRepository(<Campaign>[
        Campaign(
          id: 'campaign-1',
          name: 'Campaña',
          createdAt: DateTime.utc(2026, 8, 10, 10),
        ),
      ]);
      final package = _package();
      final rulesets = _MemoryRulesetRepository(<RulesetPackage>[package]);
      final bindings = _MemoryCampaignRulesetRepository();
      final initialize = InitializeCampaignRuleset(
        campaignRepository: campaigns,
        rulesetRepository: rulesets,
        campaignRulesetRepository: bindings,
        clock: () => DateTime.utc(2026, 8, 10, 12),
      );

      final state = await initialize(
        campaignId: 'campaign-1',
        rulesetId: 'rolemaster-rm2',
        rulesetVersion: '1.0.0',
      );

      expect(state.binding.rulesetId, 'rolemaster-rm2');
      expect(state.binding.rulesetVersion, '1.0.0');
      expect(state.binding.activeModuleIds, <String>['core', 'arms-law']);
      expect(state.overlay.isClean, isTrue);
      expect(state.overlay.overrides, isEmpty);
    });

    test('campaign rules are isolated from the immutable package', () {
      final package = _package();
      final overlay = CampaignRulesOverlay.clean(
        campaignId: 'campaign-1',
        updatedAt: DateTime.utc(2026, 8, 10, 12),
      ).replaceOverrides(
        <String, Object?>{
          'tables': <String, Object?>{
            'critical-e': <String, Object?>{'max': 120},
          },
        },
        at: DateTime.utc(2026, 8, 10, 13),
      );

      expect(overlay.isClean, isFalse);
      expect(package.data['tables'], isNotNull);
      expect(
        () => package.data['new'] = true,
        throwsUnsupportedError,
      );
      final tables = package.data['tables']! as Map<String, Object?>;
      expect(() => tables['critical-e'] = 'changed', throwsUnsupportedError);
    });

    test('rejects unknown modules and missing required modules', () async {
      final campaigns = _MemoryCampaignRepository(<Campaign>[
        Campaign(
          id: 'campaign-1',
          name: 'Campaña',
          createdAt: DateTime.utc(2026, 8, 10, 10),
        ),
      ]);
      final initialize = InitializeCampaignRuleset(
        campaignRepository: campaigns,
        rulesetRepository:
            _MemoryRulesetRepository(<RulesetPackage>[_package()]),
        campaignRulesetRepository: _MemoryCampaignRulesetRepository(),
        clock: DateTime.now,
      );

      await expectLater(
        initialize(
          campaignId: 'campaign-1',
          rulesetId: 'rolemaster-rm2',
          rulesetVersion: '1.0.0',
          activeModuleIds: <String>['unknown'],
        ),
        throwsA(isA<UnknownRulesetModuleException>()),
      );
      await expectLater(
        initialize(
          campaignId: 'campaign-1',
          rulesetId: 'rolemaster-rm2',
          rulesetVersion: '1.0.0',
          activeModuleIds: <String>['arms-law'],
        ),
        throwsA(isA<RequiredRulesetModuleMissingException>()),
      );
    });

    test('reset clears only campaign overrides and keeps the binding',
        () async {
      final repository = _MemoryCampaignRulesetRepository();
      final binding = CampaignRulesetBinding(
        campaignId: 'campaign-1',
        rulesetId: 'rolemaster-rm2',
        rulesetVersion: '1.0.0',
        activeModuleIds: <String>['core', 'arms-law'],
        boundAt: DateTime.utc(2026, 8, 10, 12),
      );
      await repository.save(
        CampaignRulesetState(
          binding: binding,
          overlay: CampaignRulesOverlay(
            campaignId: 'campaign-1',
            updatedAt: DateTime.utc(2026, 8, 10, 13),
            overrides: const <String, Object?>{
              'houseRules': <String, Object?>{'openEndedRoll': false},
            },
          ),
        ),
      );

      final reset = await ResetCampaignRules(
        repository: repository,
        clock: () => DateTime.utc(2026, 8, 10, 14),
      )('campaign-1');

      expect(reset.overlay.isClean, isTrue);
      expect(reset.binding.rulesetId, binding.rulesetId);
      expect(reset.binding.rulesetVersion, binding.rulesetVersion);
      expect(reset.binding.activeModuleIds, binding.activeModuleIds);
    });

    test('does not silently replace an initialized ruleset', () async {
      final campaigns = _MemoryCampaignRepository(<Campaign>[
        Campaign(
          id: 'campaign-1',
          name: 'Campaña',
          createdAt: DateTime.utc(2026, 8, 10, 10),
        ),
      ]);
      final repository = _MemoryCampaignRulesetRepository();
      final initialize = InitializeCampaignRuleset(
        campaignRepository: campaigns,
        rulesetRepository:
            _MemoryRulesetRepository(<RulesetPackage>[_package()]),
        campaignRulesetRepository: repository,
        clock: () => DateTime.utc(2026, 8, 10, 12),
      );

      await initialize(
        campaignId: 'campaign-1',
        rulesetId: 'rolemaster-rm2',
        rulesetVersion: '1.0.0',
      );

      await expectLater(
        initialize(
          campaignId: 'campaign-1',
          rulesetId: 'rolemaster-rm2',
          rulesetVersion: '1.0.0',
        ),
        throwsA(isA<CampaignRulesetAlreadyInitializedException>()),
      );
    });
  });
}

RulesetPackage _package() {
  return RulesetPackage(
    manifest: RulesetManifest(
      id: 'rolemaster-rm2',
      systemId: 'rolemaster',
      edition: 'RM2',
      version: '1.0.0',
      displayName: 'Rolemaster 2nd Edition',
      modules: <RulesetModuleDefinition>[
        RulesetModuleDefinition(
          id: 'core',
          name: 'Core',
          required: true,
        ),
        RulesetModuleDefinition(
          id: 'arms-law',
          name: 'Arms Law',
          enabledByDefault: true,
        ),
        RulesetModuleDefinition(
          id: 'companion-1',
          name: 'Companion I',
        ),
      ],
      sourceReferences: <String>['Character Law', 'Arms Law'],
    ),
    data: const <String, Object?>{
      'tables': <String, Object?>{
        'critical-e': <String, Object?>{'max': 100},
      },
    },
  );
}

final class _MemoryRulesetRepository implements RulesetRepository {
  _MemoryRulesetRepository(Iterable<RulesetPackage> initial) {
    for (final package in initial) {
      _packages[_key(package.manifest.id, package.manifest.version)] = package;
    }
  }

  final Map<String, RulesetPackage> _packages = <String, RulesetPackage>{};

  @override
  Future<List<RulesetPackage>> getAvailablePackages() async =>
      List<RulesetPackage>.unmodifiable(_packages.values);

  @override
  Future<RulesetPackage?> getPackage({
    required String rulesetId,
    required String version,
  }) async {
    return _packages[_key(rulesetId, version)];
  }

  String _key(String id, String version) => '$id@$version';
}

final class _MemoryCampaignRulesetRepository
    implements CampaignRulesetRepository {
  final Map<String, CampaignRulesetState> _states =
      <String, CampaignRulesetState>{};

  @override
  Future<CampaignRulesetState?> getForCampaign(String campaignId) async =>
      _states[campaignId];

  @override
  Future<void> migrate({
    required CampaignRulesetState expected,
    required CampaignRulesetState next,
  }) async {
    final current = _states[expected.binding.campaignId];
    if (current == null ||
        current.binding.rulesetId != expected.binding.rulesetId ||
        current.binding.rulesetVersion != expected.binding.rulesetVersion ||
        current.binding.boundAt != expected.binding.boundAt ||
        current.overlay.updatedAt != expected.overlay.updatedAt) {
      throw StateError('Campaign ruleset changed during migration.');
    }
    _states[expected.binding.campaignId] = next;
  }

  @override
  Future<void> save(CampaignRulesetState state) async {
    _states[state.binding.campaignId] = state;
  }
}

final class _MemoryCampaignRepository implements CampaignRepository {
  _MemoryCampaignRepository(Iterable<Campaign> initial) {
    for (final campaign in initial) {
      _campaigns[campaign.id] = campaign;
    }
  }

  final Map<String, Campaign> _campaigns = <String, Campaign>{};

  @override
  Future<List<Campaign>> getAll({bool includeArchived = false}) async =>
      _campaigns.values
          .where((campaign) => includeArchived || !campaign.isArchived)
          .toList(growable: false);

  @override
  Future<Campaign?> getById(String id) async => _campaigns[id];

  @override
  Future<void> save(Campaign campaign) async {
    _campaigns[campaign.id] = campaign;
  }
}

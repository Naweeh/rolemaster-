import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  group('Inventory foundation', () {
    test('reads item definitions from active ruleset modules', () {
      final catalog = RulesetItemCatalog.fromPackage(_package());

      expect(catalog.definitions, hasLength(3));
      expect(catalog.getById('longsword')!.category, 'Weapon');
      expect(
        catalog.availableForModules(<String>['core']).map((item) => item.id),
        <String>['longsword', 'backpack'],
      );
      final properties = catalog.getById('longsword')!.properties;
      expect(properties['hands'], 1);
      expect(() => properties['hands'] = 2, throwsUnsupportedError);
    });

    test('creates ruleset-backed and custom campaign items', () async {
      final fixtures = _Fixtures();
      final ids = <String>['item-1', 'item-2'].iterator;
      final create = CreateItemInstance(
        campaignRepository: fixtures.campaigns,
        rulesetRepository: fixtures.rulesets,
        campaignRulesetRepository: fixtures.campaignRulesets,
        itemRepository: fixtures.items,
        idGenerator: () {
          ids.moveNext();
          return ids.current;
        },
        clock: () => DateTime.utc(2026, 8, 10, 16),
      );

      final sword = await create(
        campaignId: 'campaign-1',
        definitionId: 'longsword',
        quantity: 1,
      );
      final custom = await create(
        campaignId: 'campaign-1',
        customName: 'Llave oxidada',
        quantity: 2,
      );

      expect(sword.definitionId, 'longsword');
      expect(sword.isCustom, isFalse);
      expect(custom.isCustom, isTrue);
      expect(custom.customName, 'Llave oxidada');
      expect(await fixtures.items.getForCampaign('campaign-1'), hasLength(2));
    });

    test('rejects definition from an inactive ruleset module', () async {
      final fixtures = _Fixtures();
      final create = CreateItemInstance(
        campaignRepository: fixtures.campaigns,
        rulesetRepository: fixtures.rulesets,
        campaignRulesetRepository: fixtures.campaignRulesets,
        itemRepository: fixtures.items,
        idGenerator: () => 'item-1',
        clock: DateTime.now,
      );

      await expectLater(
        create(
          campaignId: 'campaign-1',
          definitionId: 'herb-kit',
        ),
        throwsA(isA<ItemModuleInactiveException>()),
      );
    });

    test('moves items into containers and rejects containment cycles',
        () async {
      final fixtures = _Fixtures();
      final ids = <String>['bag', 'sword'].iterator;
      final create = CreateItemInstance(
        campaignRepository: fixtures.campaigns,
        rulesetRepository: fixtures.rulesets,
        campaignRulesetRepository: fixtures.campaignRulesets,
        itemRepository: fixtures.items,
        idGenerator: () {
          ids.moveNext();
          return ids.current;
        },
        clock: () => DateTime.utc(2026, 8, 10, 16),
      );
      final bag = await create(
        campaignId: 'campaign-1',
        definitionId: 'backpack',
        placement: ItemPlacement(
          holder: InventoryHolderRef(
            entityType: 'character',
            entityId: 'character-1',
          ),
        ),
      );
      final sword = await create(
        campaignId: 'campaign-1',
        definitionId: 'longsword',
        placement: ItemPlacement(
          holder: InventoryHolderRef(
            entityType: 'character',
            entityId: 'character-1',
          ),
        ),
      );
      final transfer = TransferItemInstance(
        repository: fixtures.items,
        clock: () => DateTime.utc(2026, 8, 10, 17),
      );

      final containedSword = await transfer(
        itemId: sword.id,
        placement: ItemPlacement(containerItemId: bag.id),
      );

      expect(containedSword.placement.containerItemId, bag.id);
      expect(containedSword.equipped, isFalse);
      await expectLater(
        transfer(
          itemId: bag.id,
          placement: ItemPlacement(containerItemId: sword.id),
        ),
        throwsA(isA<ItemContainmentCycleException>()),
      );
    });
  });
}

RulesetPackage _package() {
  return RulesetPackage(
    manifest: RulesetManifest(
      id: 'rolemaster-demo',
      systemId: 'rolemaster',
      edition: 'Demo',
      version: '0.2.0',
      displayName: 'Rolemaster Demo',
      modules: <RulesetModuleDefinition>[
        RulesetModuleDefinition(id: 'core', name: 'Core', required: true),
        RulesetModuleDefinition(id: 'companion-1', name: 'Companion I'),
      ],
    ),
    data: const <String, Object?>{
      'items': <Object?>[
        <String, Object?>{
          'id': 'longsword',
          'name': 'Longsword',
          'moduleId': 'core',
          'category': 'Weapon',
          'properties': <String, Object?>{'hands': 1},
        },
        <String, Object?>{
          'id': 'backpack',
          'name': 'Backpack',
          'moduleId': 'core',
          'category': 'Container',
        },
        <String, Object?>{
          'id': 'herb-kit',
          'name': 'Herb Kit',
          'moduleId': 'companion-1',
          'category': 'Gear',
        },
      ],
    },
  );
}

final class _Fixtures {
  _Fixtures() {
    campaigns = _MemoryCampaignRepository(
      <Campaign>[
        Campaign(
          id: 'campaign-1',
          name: 'Campaña',
          createdAt: DateTime.utc(2026, 8, 10, 10),
        ),
      ],
    );
    rulesets = _MemoryRulesetRepository(<RulesetPackage>[_package()]);
    campaignRulesets = _MemoryCampaignRulesetRepository(
      CampaignRulesetState(
        binding: CampaignRulesetBinding(
          campaignId: 'campaign-1',
          rulesetId: 'rolemaster-demo',
          rulesetVersion: '0.2.0',
          activeModuleIds: <String>['core'],
          boundAt: DateTime.utc(2026, 8, 10, 11),
        ),
        overlay: CampaignRulesOverlay.clean(
          campaignId: 'campaign-1',
          updatedAt: DateTime.utc(2026, 8, 10, 11),
        ),
      ),
    );
    items = _MemoryItemRepository();
  }

  late final _MemoryCampaignRepository campaigns;
  late final _MemoryRulesetRepository rulesets;
  late final _MemoryCampaignRulesetRepository campaignRulesets;
  late final _MemoryItemRepository items;
}

final class _MemoryCampaignRepository implements CampaignRepository {
  _MemoryCampaignRepository(Iterable<Campaign> campaigns) {
    for (final campaign in campaigns) {
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

final class _MemoryRulesetRepository implements RulesetRepository {
  _MemoryRulesetRepository(Iterable<RulesetPackage> packages) {
    for (final package in packages) {
      _packages['${package.manifest.id}@${package.manifest.version}'] = package;
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
  }) async =>
      _packages['$rulesetId@$version'];
}

final class _MemoryCampaignRulesetRepository
    implements CampaignRulesetRepository {
  _MemoryCampaignRulesetRepository(CampaignRulesetState state) {
    _states[state.binding.campaignId] = state;
  }

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
        current.binding.rulesetVersion != expected.binding.rulesetVersion) {
      throw StateError('Campaign ruleset changed during migration.');
    }
    _states[expected.binding.campaignId] = next;
  }

  @override
  Future<void> save(CampaignRulesetState state) async {
    _states[state.binding.campaignId] = state;
  }
}

final class _MemoryItemRepository implements ItemInstanceRepository {
  final Map<String, ItemInstance> _items = <String, ItemInstance>{};

  @override
  Future<ItemInstance?> getById(String id) async => _items[id];

  @override
  Future<List<ItemInstance>> getForCampaign(String campaignId) async =>
      _items.values
          .where((item) => item.campaignId == campaignId)
          .toList(growable: false);

  @override
  Future<void> save(ItemInstance item) async {
    _items[item.id] = item;
  }
}

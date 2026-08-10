import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  group('Creature use cases', () {
    test('creates a placed creature in an active campaign', () async {
      final campaigns = _MemoryCampaignRepository(<Campaign>[
        Campaign(
          id: 'campaign-1',
          name: 'Campaña',
          createdAt: DateTime.utc(2026, 8, 10, 9),
        ),
      ]);
      final worlds = _MemoryWorldRepository(
        worlds: <World>[
          World(
            id: 'world-1',
            campaignId: 'campaign-1',
            name: 'Mundo',
            createdAt: DateTime.utc(2026, 8, 10, 9),
          ),
        ],
        locations: <Location>[
          Location(
            id: 'location-1',
            worldId: 'world-1',
            name: 'Bosque',
            createdAt: DateTime.utc(2026, 8, 10, 9),
          ),
        ],
      );
      final creatures = _MemoryCreatureRepository();
      final create = CreateCreature(
        repository: creatures,
        campaignRepository: campaigns,
        worldRepository: worlds,
        idGenerator: () => 'creature-1',
        clock: () => DateTime.utc(2026, 8, 10, 12),
      );

      final creature = await create(
        campaignId: 'campaign-1',
        name: 'Lobo Gris',
        metadata: CreatureMetadata(species: 'Lobo', category: 'Bestia'),
        placement: CreaturePlacement(
          worldId: 'world-1',
          locationId: 'location-1',
        ),
      );

      expect(creature.id, 'creature-1');
      expect(creature.metadata.species, 'Lobo');
      expect(creature.placement.locationId, 'location-1');
    });

    test('rejects placement outside campaign or selected world', () async {
      final campaigns = _MemoryCampaignRepository(<Campaign>[
        Campaign(
          id: 'campaign-1',
          name: 'Campaña',
          createdAt: DateTime.utc(2026, 8, 10, 9),
        ),
      ]);
      final worlds = _MemoryWorldRepository(
        worlds: <World>[
          World(
            id: 'world-other',
            campaignId: 'campaign-2',
            name: 'Otro',
            createdAt: DateTime.utc(2026, 8, 10, 9),
          ),
          World(
            id: 'world-1',
            campaignId: 'campaign-1',
            name: 'Propio',
            createdAt: DateTime.utc(2026, 8, 10, 9),
          ),
          World(
            id: 'world-2',
            campaignId: 'campaign-1',
            name: 'Segundo',
            createdAt: DateTime.utc(2026, 8, 10, 9),
          ),
        ],
        locations: <Location>[
          Location(
            id: 'location-2',
            worldId: 'world-2',
            name: 'Otro sitio',
            createdAt: DateTime.utc(2026, 8, 10, 9),
          ),
        ],
      );
      final create = CreateCreature(
        repository: _MemoryCreatureRepository(),
        campaignRepository: campaigns,
        worldRepository: worlds,
        idGenerator: () => 'creature-1',
        clock: () => DateTime.utc(2026, 8, 10, 12),
      );
      final metadata = CreatureMetadata(species: 'Lobo');

      await expectLater(
        create(
          campaignId: 'campaign-1',
          name: 'Inválida',
          metadata: metadata,
          placement: CreaturePlacement(worldId: 'world-other'),
        ),
        throwsStateError,
      );
      await expectLater(
        create(
          campaignId: 'campaign-1',
          name: 'Inválida',
          metadata: metadata,
          placement: CreaturePlacement(
            worldId: 'world-1',
            locationId: 'location-2',
          ),
        ),
        throwsStateError,
      );
    });

    test('gets, updates, archives and filters creatures', () async {
      final repository = _MemoryCreatureRepository(<Creature>[
        Creature(
          id: 'creature-1',
          campaignId: 'campaign-1',
          name: 'Lobo',
          createdAt: DateTime.utc(2026, 8, 10, 10),
          metadata: CreatureMetadata(species: 'Lobo'),
        ),
        Creature(
          id: 'creature-2',
          campaignId: 'campaign-2',
          name: 'Oso',
          createdAt: DateTime.utc(2026, 8, 10, 10),
          metadata: CreatureMetadata(species: 'Oso'),
        ),
      ]);
      final update = UpdateCreature(
        repository: repository,
        worldRepository: _MemoryWorldRepository(),
        clock: () => DateTime.utc(2026, 8, 10, 11),
      );
      final archive = ArchiveCreature(
        repository: repository,
        clock: () => DateTime.utc(2026, 8, 10, 12),
      );
      final list = ListCreatures(repository: repository);

      expect((await GetCreature(repository: repository)('creature-1')).name, 'Lobo');
      final updated = await update(
        'creature-1',
        name: 'Lobo Alfa',
        metadata: CreatureMetadata(species: 'Lobo', category: 'Bestia'),
      );
      expect(updated.name, 'Lobo Alfa');

      await archive('creature-1');
      expect(await list('campaign-1'), isEmpty);
      expect(await list('campaign-1', includeArchived: true), hasLength(1));
      expect(await list('campaign-2'), hasLength(1));
    });

    test('reports missing creatures', () async {
      final repository = _MemoryCreatureRepository();

      await expectLater(
        GetCreature(repository: repository)('missing'),
        throwsA(isA<CreatureNotFoundException>()),
      );
      await expectLater(
        ArchiveCreature(repository: repository, clock: DateTime.now)('missing'),
        throwsA(isA<CreatureNotFoundException>()),
      );
    });
  });
}

final class _MemoryCreatureRepository implements CreatureRepository {
  _MemoryCreatureRepository([
    Iterable<Creature> initial = const <Creature>[],
  ]) {
    for (final creature in initial) {
      _creatures[creature.id] = creature;
    }
  }

  final Map<String, Creature> _creatures = <String, Creature>{};

  @override
  Future<Creature?> getById(String id) async => _creatures[id];

  @override
  Future<List<Creature>> getForCampaign(
    String campaignId, {
    bool includeArchived = false,
  }) async {
    return _creatures.values
        .where(
          (creature) =>
              creature.campaignId == campaignId &&
              (includeArchived || !creature.isArchived),
        )
        .toList(growable: false);
  }

  @override
  Future<void> save(Creature creature) async {
    _creatures[creature.id] = creature;
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
  Future<List<Campaign>> getAll({bool includeArchived = false}) async {
    return _campaigns.values
        .where((campaign) => includeArchived || !campaign.isArchived)
        .toList(growable: false);
  }

  @override
  Future<Campaign?> getById(String id) async => _campaigns[id];

  @override
  Future<void> save(Campaign campaign) async {
    _campaigns[campaign.id] = campaign;
  }
}

final class _MemoryWorldRepository implements WorldRepository {
  _MemoryWorldRepository({
    Iterable<World> worlds = const <World>[],
    Iterable<Location> locations = const <Location>[],
  }) {
    for (final world in worlds) {
      _worlds[world.id] = world;
    }
    for (final location in locations) {
      _locations[location.id] = location;
    }
  }

  final Map<String, World> _worlds = <String, World>{};
  final Map<String, Region> _regions = <String, Region>{};
  final Map<String, Location> _locations = <String, Location>{};

  @override
  Future<World?> getWorldById(String id) async => _worlds[id];

  @override
  Future<List<World>> getWorldsForCampaign(String campaignId) async => _worlds.values
      .where((world) => world.campaignId == campaignId)
      .toList(growable: false);

  @override
  Future<void> saveWorld(World world) async => _worlds[world.id] = world;

  @override
  Future<Region?> getRegionById(String id) async => _regions[id];

  @override
  Future<List<Region>> getRegionsForWorld(String worldId) async => _regions.values
      .where((region) => region.worldId == worldId)
      .toList(growable: false);

  @override
  Future<void> saveRegion(Region region) async => _regions[region.id] = region;

  @override
  Future<Location?> getLocationById(String id) async => _locations[id];

  @override
  Future<List<Location>> getLocationsForWorld(String worldId) async => _locations.values
      .where((location) => location.worldId == worldId)
      .toList(growable: false);

  @override
  Future<void> saveLocation(Location location) async => _locations[location.id] = location;
}

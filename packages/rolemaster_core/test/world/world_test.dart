import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  group('World domain', () {
    test('normalizes world metadata and updates world state', () {
      final world = World(
        id: ' world-1 ',
        campaignId: ' campaign-1 ',
        name: ' Mundo ',
        createdAt: DateTime.utc(2026, 8, 10, 10),
      );
      final metadata = WorldMetadata(
        description: '  Tierra conocida  ',
        tags: <String>['fantasia', ' FANTASIA ', 'principal'],
      );

      final updated = world.update(
        name: 'Mundo Principal',
        metadata: metadata,
        at: DateTime.utc(2026, 8, 10, 11),
      );

      expect(updated.id, 'world-1');
      expect(updated.campaignId, 'campaign-1');
      expect(updated.name, 'Mundo Principal');
      expect(updated.metadata.description, 'Tierra conocida');
      expect(updated.metadata.tags, <String>['fantasia', 'principal']);
    });

    test('region cannot be its own parent', () {
      expect(
        () => Region(
          id: 'region-1',
          worldId: 'world-1',
          name: 'Región',
          parentRegionId: 'region-1',
          createdAt: DateTime.utc(2026, 8, 10),
        ),
        throwsArgumentError,
      );
    });

    test('location cannot be its own parent', () {
      expect(
        () => Location(
          id: 'location-1',
          worldId: 'world-1',
          name: 'Lugar',
          parentLocationId: 'location-1',
          createdAt: DateTime.utc(2026, 8, 10),
        ),
        throwsArgumentError,
      );
    });
  });

  group('World use cases', () {
    test('CreateWorld creates a world for an active campaign', () async {
      final campaigns = _MemoryCampaignRepository(<Campaign>[
        _campaign('campaign-1'),
      ]);
      final worlds = _MemoryWorldRepository();
      final useCase = CreateWorld(
        campaignRepository: campaigns,
        worldRepository: worlds,
        idGenerator: () => 'world-1',
        clock: () => DateTime.utc(2026, 8, 10, 12),
      );

      final world = await useCase(
        campaignId: ' campaign-1 ',
        name: 'Tierra Media',
      );

      expect(world.id, 'world-1');
      expect(world.campaignId, 'campaign-1');
      expect((await worlds.getWorldById('world-1'))?.name, 'Tierra Media');
    });

    test('CreateWorld rejects an archived campaign', () async {
      final campaigns = _MemoryCampaignRepository(<Campaign>[
        _campaign('campaign-1').archive(at: DateTime.utc(2026, 8, 10, 11)),
      ]);
      final useCase = CreateWorld(
        campaignRepository: campaigns,
        worldRepository: _MemoryWorldRepository(),
        idGenerator: () => 'world-1',
        clock: () => DateTime.utc(2026, 8, 10, 12),
      );

      await expectLater(
        useCase(campaignId: 'campaign-1', name: 'Mundo'),
        throwsStateError,
      );
    });

    test('AddRegion rejects a parent from another world', () async {
      final repository = _MemoryWorldRepository(
        worlds: <World>[_world('world-1'), _world('world-2')],
        regions: <Region>[
          Region(
            id: 'region-other',
            worldId: 'world-2',
            name: 'Otra',
            createdAt: DateTime.utc(2026, 8, 10, 10),
          ),
        ],
      );
      final useCase = AddRegion(
        repository: repository,
        idGenerator: () => 'region-1',
        clock: () => DateTime.utc(2026, 8, 10, 12),
      );

      await expectLater(
        useCase(
          worldId: 'world-1',
          name: 'Nueva',
          parentRegionId: 'region-other',
        ),
        throwsStateError,
      );
    });

    test('AddLocation inherits the region of its parent', () async {
      final repository = _MemoryWorldRepository(
        worlds: <World>[_world('world-1')],
        regions: <Region>[
          Region(
            id: 'region-1',
            worldId: 'world-1',
            name: 'Norte',
            createdAt: DateTime.utc(2026, 8, 10, 10),
          ),
        ],
        locations: <Location>[
          Location(
            id: 'city-1',
            worldId: 'world-1',
            name: 'Ciudad',
            regionId: 'region-1',
            createdAt: DateTime.utc(2026, 8, 10, 10),
          ),
        ],
      );
      final useCase = AddLocation(
        repository: repository,
        idGenerator: () => 'inn-1',
        clock: () => DateTime.utc(2026, 8, 10, 12),
      );

      final location = await useCase(
        worldId: 'world-1',
        name: 'Posada',
        parentLocationId: 'city-1',
      );

      expect(location.parentLocationId, 'city-1');
      expect(location.regionId, 'region-1');
    });

    test('AddLocation rejects a region different from its parent', () async {
      final repository = _MemoryWorldRepository(
        worlds: <World>[_world('world-1')],
        regions: <Region>[
          Region(
            id: 'region-1',
            worldId: 'world-1',
            name: 'Norte',
            createdAt: DateTime.utc(2026, 8, 10, 10),
          ),
          Region(
            id: 'region-2',
            worldId: 'world-1',
            name: 'Sur',
            createdAt: DateTime.utc(2026, 8, 10, 10),
          ),
        ],
        locations: <Location>[
          Location(
            id: 'city-1',
            worldId: 'world-1',
            name: 'Ciudad',
            regionId: 'region-1',
            createdAt: DateTime.utc(2026, 8, 10, 10),
          ),
        ],
      );
      final useCase = AddLocation(
        repository: repository,
        idGenerator: () => 'location-1',
        clock: () => DateTime.utc(2026, 8, 10, 12),
      );

      await expectLater(
        useCase(
          worldId: 'world-1',
          name: 'Lugar',
          regionId: 'region-2',
          parentLocationId: 'city-1',
        ),
        throwsStateError,
      );
    });
  });
}

Campaign _campaign(String id) {
  return Campaign(
    id: id,
    name: 'Campaign',
    createdAt: DateTime.utc(2026, 8, 10, 10),
  );
}

World _world(String id) {
  return World(
    id: id,
    campaignId: 'campaign-1',
    name: 'World',
    createdAt: DateTime.utc(2026, 8, 10, 10),
  );
}

final class _MemoryCampaignRepository implements CampaignRepository {
  _MemoryCampaignRepository(
      [Iterable<Campaign> campaigns = const <Campaign>[]]) {
    for (final campaign in campaigns) {
      _campaigns[campaign.id] = campaign;
    }
  }

  final Map<String, Campaign> _campaigns = <String, Campaign>{};

  @override
  Future<Campaign?> getById(String id) async => _campaigns[id];

  @override
  Future<List<Campaign>> getAll({bool includeArchived = false}) async {
    return _campaigns.values
        .where((campaign) => includeArchived || !campaign.isArchived)
        .toList(growable: false);
  }

  @override
  Future<void> save(Campaign campaign) async {
    _campaigns[campaign.id] = campaign;
  }
}

final class _MemoryWorldRepository implements WorldRepository {
  _MemoryWorldRepository({
    Iterable<World> worlds = const <World>[],
    Iterable<Region> regions = const <Region>[],
    Iterable<Location> locations = const <Location>[],
  }) {
    for (final world in worlds) {
      _worlds[world.id] = world;
    }
    for (final region in regions) {
      _regions[region.id] = region;
    }
    for (final location in locations) {
      _locations[location.id] = location;
    }
  }

  final Map<String, World> _worlds = <String, World>{};
  final Map<String, Region> _regions = <String, Region>{};
  final Map<String, Location> _locations = <String, Location>{};

  @override
  Future<Location?> getLocationById(String id) async => _locations[id];

  @override
  Future<List<Location>> getLocationsForWorld(String worldId) async {
    return _locations.values
        .where((location) => location.worldId == worldId)
        .toList(growable: false);
  }

  @override
  Future<Region?> getRegionById(String id) async => _regions[id];

  @override
  Future<List<Region>> getRegionsForWorld(String worldId) async {
    return _regions.values
        .where((region) => region.worldId == worldId)
        .toList(growable: false);
  }

  @override
  Future<World?> getWorldById(String id) async => _worlds[id];

  @override
  Future<List<World>> getWorldsForCampaign(String campaignId) async {
    return _worlds.values
        .where((world) => world.campaignId == campaignId)
        .toList(growable: false);
  }

  @override
  Future<void> saveLocation(Location location) async {
    _locations[location.id] = location;
  }

  @override
  Future<void> saveRegion(Region region) async {
    _regions[region.id] = region;
  }

  @override
  Future<void> saveWorld(World world) async {
    _worlds[world.id] = world;
  }
}

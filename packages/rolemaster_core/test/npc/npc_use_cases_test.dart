import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  group('NPC use cases', () {
    test('creates a placed NPC in an active campaign', () async {
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
            name: 'Posada',
            createdAt: DateTime.utc(2026, 8, 10, 9),
          ),
        ],
      );
      final npcs = _MemoryNpcRepository();
      final create = CreateNpc(
        repository: npcs,
        campaignRepository: campaigns,
        worldRepository: worlds,
        idGenerator: () => 'npc-1',
        clock: () => DateTime.utc(2026, 8, 10, 12),
      );

      final npc = await create(
        campaignId: 'campaign-1',
        name: 'Guardián',
        metadata: NpcMetadata(
          nativeLanguage: 'Sindarin',
          knownLanguages: <String>['Común'],
        ),
        placement: NpcPlacement(
          worldId: 'world-1',
          locationId: 'location-1',
        ),
      );

      expect(npc.id, 'npc-1');
      expect(npc.metadata.nativeLanguage, 'Sindarin');
      expect(npc.placement.locationId, 'location-1');
      expect(await npcs.getById('npc-1'), same(npc));
    });

    test('rejects placement in another campaign or world', () async {
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
      final create = CreateNpc(
        repository: _MemoryNpcRepository(),
        campaignRepository: campaigns,
        worldRepository: worlds,
        idGenerator: () => 'npc-1',
        clock: () => DateTime.utc(2026, 8, 10, 12),
      );
      final metadata = NpcMetadata(nativeLanguage: 'Común');

      await expectLater(
        create(
          campaignId: 'campaign-1',
          name: 'Inválido',
          metadata: metadata,
          placement: NpcPlacement(worldId: 'world-other'),
        ),
        throwsStateError,
      );
      await expectLater(
        create(
          campaignId: 'campaign-1',
          name: 'Inválido',
          metadata: metadata,
          placement: NpcPlacement(
            worldId: 'world-1',
            locationId: 'location-2',
          ),
        ),
        throwsStateError,
      );
    });

    test('updates, unplaces, archives and filters NPCs', () async {
      final repository = _MemoryNpcRepository(<Npc>[
        Npc(
          id: 'npc-1',
          campaignId: 'campaign-1',
          name: 'Guardián',
          createdAt: DateTime.utc(2026, 8, 10, 10),
          metadata: NpcMetadata(nativeLanguage: 'Común'),
        ),
        Npc(
          id: 'npc-2',
          campaignId: 'campaign-2',
          name: 'Otro',
          createdAt: DateTime.utc(2026, 8, 10, 10),
          metadata: NpcMetadata(nativeLanguage: 'Común'),
        ),
      ]);
      final worlds = _MemoryWorldRepository();
      final update = UpdateNpc(
        repository: repository,
        worldRepository: worlds,
        clock: () => DateTime.utc(2026, 8, 10, 11),
      );
      final archive = ArchiveNpc(
        repository: repository,
        clock: () => DateTime.utc(2026, 8, 10, 12),
      );
      final list = ListNpcs(repository: repository);

      final updated = await update(
        'npc-1',
        name: 'Guardián Mayor',
        metadata: NpcMetadata(
          nativeLanguage: 'Común',
          knownLanguages: <String>['Khuzdul'],
        ),
        placement: NpcPlacement.unplaced(),
      );
      expect(updated.name, 'Guardián Mayor');
      expect(updated.metadata.knownLanguages, <String>['Khuzdul']);

      await archive('npc-1');
      expect(await list('campaign-1'), isEmpty);
      expect(await list('campaign-1', includeArchived: true), hasLength(1));
      expect(await list('campaign-2'), hasLength(1));
    });

    test('reports missing NPCs for get, update and archive', () async {
      final repository = _MemoryNpcRepository();
      final worlds = _MemoryWorldRepository();

      await expectLater(
        GetNpc(repository: repository)('missing'),
        throwsA(isA<NpcNotFoundException>()),
      );
      await expectLater(
        UpdateNpc(
          repository: repository,
          worldRepository: worlds,
          clock: DateTime.now,
        )('missing', name: 'No existe'),
        throwsA(isA<NpcNotFoundException>()),
      );
      await expectLater(
        ArchiveNpc(
          repository: repository,
          clock: DateTime.now,
        )('missing'),
        throwsA(isA<NpcNotFoundException>()),
      );
    });
  });
}

final class _MemoryNpcRepository implements NpcRepository {
  _MemoryNpcRepository([Iterable<Npc> initial = const <Npc>[]]) {
    for (final npc in initial) {
      _npcs[npc.id] = npc;
    }
  }

  final Map<String, Npc> _npcs = <String, Npc>{};

  @override
  Future<Npc?> getById(String id) async => _npcs[id];

  @override
  Future<List<Npc>> getForCampaign(
    String campaignId, {
    bool includeArchived = false,
  }) async {
    return _npcs.values
        .where(
          (npc) =>
              npc.campaignId == campaignId &&
              (includeArchived || !npc.isArchived),
        )
        .toList(growable: false);
  }

  @override
  Future<void> save(Npc npc) async {
    _npcs[npc.id] = npc;
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
  final Map<String, Location> _locations = <String, Location>{};
  final Map<String, Region> _regions = <String, Region>{};

  @override
  Future<World?> getWorldById(String id) async => _worlds[id];

  @override
  Future<List<World>> getWorldsForCampaign(String campaignId) async {
    return _worlds.values
        .where((world) => world.campaignId == campaignId)
        .toList(growable: false);
  }

  @override
  Future<void> saveWorld(World world) async {
    _worlds[world.id] = world;
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
  Future<void> saveRegion(Region region) async {
    _regions[region.id] = region;
  }

  @override
  Future<Location?> getLocationById(String id) async => _locations[id];

  @override
  Future<List<Location>> getLocationsForWorld(String worldId) async {
    return _locations.values
        .where((location) => location.worldId == worldId)
        .toList(growable: false);
  }

  @override
  Future<void> saveLocation(Location location) async {
    _locations[location.id] = location;
  }
}

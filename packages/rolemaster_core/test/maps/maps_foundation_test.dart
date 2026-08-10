import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  group('Maps foundation', () {
    test('creates a map linked to canonical world and location', () async {
      final fixtures = _Fixtures();
      final create = CreateSceneMap(
        campaignRepository: fixtures.campaigns,
        worldRepository: fixtures.worlds,
        sceneMapRepository: fixtures.maps,
        idGenerator: () => 'map-1',
        clock: () => DateTime.utc(2026, 8, 10, 18),
      );

      final map = await create(
        campaignId: 'campaign-1',
        name: 'Posada del Camino',
        worldId: 'world-1',
        locationId: 'location-1',
        coordinateSpace: SceneCoordinateSpace(width: 100, height: 80),
      );

      expect(map.worldId, 'world-1');
      expect(map.locationId, 'location-1');
      expect(map.coordinateSpace.contains(100, 80), isTrue);
      expect(await fixtures.maps.getMapById('map-1'), same(map));
    });

    test('rejects a location from another world', () async {
      final fixtures = _Fixtures();
      final create = CreateSceneMap(
        campaignRepository: fixtures.campaigns,
        worldRepository: fixtures.worlds,
        sceneMapRepository: fixtures.maps,
        idGenerator: () => 'map-1',
        clock: DateTime.now,
      );

      await expectLater(
        create(
          campaignId: 'campaign-1',
          name: 'Inválido',
          worldId: 'world-1',
          locationId: 'location-2',
          coordinateSpace: SceneCoordinateSpace(width: 10, height: 10),
        ),
        throwsStateError,
      );
    });

    test('adds ordered layers with GM/shared visibility', () async {
      final fixtures = _Fixtures();
      await fixtures.maps.saveMap(_map());
      var nextId = 0;
      final add = AddSceneLayer(
        repository: fixtures.maps,
        idGenerator: () => 'layer-${++nextId}',
      );

      final base = await add(
        sceneMapId: 'map-1',
        name: 'Escena pública',
        orderIndex: 0,
        visibility: SceneLayerVisibility.shared,
      );
      final secrets = await add(
        sceneMapId: 'map-1',
        name: 'Secretos GM',
        orderIndex: 1,
      );

      expect(base.visibility, SceneLayerVisibility.shared);
      expect(secrets.visibility, SceneLayerVisibility.gmOnly);
      await expectLater(
        add(sceneMapId: 'map-1', name: 'Duplicada', orderIndex: 1),
        throwsA(isA<SceneLayerOrderConflictException>()),
      );
    });

    test('positions generic entities inside the logical map space', () async {
      final fixtures = _Fixtures();
      await fixtures.maps.saveMap(_map());
      await fixtures.maps.saveLayer(
        SceneLayer(
          id: 'tokens',
          sceneMapId: 'map-1',
          name: 'Tokens',
          orderIndex: 2,
          visibility: SceneLayerVisibility.shared,
        ),
      );
      final setPosition = SetSceneEntityPosition(
        repository: fixtures.maps,
        clock: () => DateTime.utc(2026, 8, 10, 19),
      );

      final position = await setPosition(
        sceneMapId: 'map-1',
        entityType: 'npc',
        entityId: 'npc-1',
        x: 42.5,
        y: 15,
        layerId: 'tokens',
      );

      expect(position.entityType, 'npc');
      expect(position.layerId, 'tokens');
      expect(
        await fixtures.maps.getEntityPosition(
          sceneMapId: 'map-1',
          entityType: 'npc',
          entityId: 'npc-1',
        ),
        same(position),
      );

      await expectLater(
        setPosition(
          sceneMapId: 'map-1',
          entityType: 'npc',
          entityId: 'npc-1',
          x: 101,
          y: 15,
        ),
        throwsA(isA<ScenePositionOutsideMapException>()),
      );
    });
  });
}

SceneMap _map() => SceneMap(
      id: 'map-1',
      campaignId: 'campaign-1',
      name: 'Mapa',
      coordinateSpace: SceneCoordinateSpace(width: 100, height: 80),
      createdAt: DateTime.utc(2026, 8, 10, 18),
    );

final class _Fixtures {
  _Fixtures() {
    campaigns = _MemoryCampaignRepository(<Campaign>[
      Campaign(
        id: 'campaign-1',
        name: 'Campaña',
        createdAt: DateTime.utc(2026, 8, 10, 10),
      ),
    ]);
    worlds = _MemoryWorldRepository(
      worlds: <World>[
        World(
          id: 'world-1',
          campaignId: 'campaign-1',
          name: 'Mundo',
          createdAt: DateTime.utc(2026, 8, 10, 11),
        ),
        World(
          id: 'world-2',
          campaignId: 'campaign-1',
          name: 'Otro mundo',
          createdAt: DateTime.utc(2026, 8, 10, 11),
        ),
      ],
      locations: <Location>[
        Location(
          id: 'location-1',
          worldId: 'world-1',
          name: 'Posada',
          createdAt: DateTime.utc(2026, 8, 10, 12),
        ),
        Location(
          id: 'location-2',
          worldId: 'world-2',
          name: 'Torre',
          createdAt: DateTime.utc(2026, 8, 10, 12),
        ),
      ],
    );
    maps = _MemorySceneMapRepository();
  }

  late final _MemoryCampaignRepository campaigns;
  late final _MemoryWorldRepository worlds;
  late final _MemorySceneMapRepository maps;
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
  Future<List<World>> getWorldsForCampaign(String campaignId) async =>
      _worlds.values
          .where((world) => world.campaignId == campaignId)
          .toList(growable: false);

  @override
  Future<void> saveWorld(World world) async => _worlds[world.id] = world;

  @override
  Future<Region?> getRegionById(String id) async => _regions[id];

  @override
  Future<List<Region>> getRegionsForWorld(String worldId) async =>
      _regions.values
          .where((region) => region.worldId == worldId)
          .toList(growable: false);

  @override
  Future<void> saveRegion(Region region) async => _regions[region.id] = region;

  @override
  Future<Location?> getLocationById(String id) async => _locations[id];

  @override
  Future<List<Location>> getLocationsForWorld(String worldId) async =>
      _locations.values
          .where((location) => location.worldId == worldId)
          .toList(growable: false);

  @override
  Future<void> saveLocation(Location location) async =>
      _locations[location.id] = location;
}

final class _MemorySceneMapRepository implements SceneMapRepository {
  final Map<String, SceneMap> _maps = <String, SceneMap>{};
  final Map<String, SceneLayer> _layers = <String, SceneLayer>{};
  final Map<String, SceneEntityPosition> _positions =
      <String, SceneEntityPosition>{};

  String _positionKey(String mapId, String type, String id) =>
      '$mapId::$type::$id';

  @override
  Future<SceneMap?> getMapById(String id) async => _maps[id];

  @override
  Future<List<SceneMap>> getMapsForCampaign(String campaignId) async =>
      _maps.values
          .where((map) => map.campaignId == campaignId)
          .toList(growable: false);

  @override
  Future<void> saveMap(SceneMap map) async => _maps[map.id] = map;

  @override
  Future<SceneLayer?> getLayerById(String id) async => _layers[id];

  @override
  Future<List<SceneLayer>> getLayersForMap(String sceneMapId) async =>
      _layers.values
          .where((layer) => layer.sceneMapId == sceneMapId)
          .toList(growable: false)
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  @override
  Future<void> saveLayer(SceneLayer layer) async => _layers[layer.id] = layer;

  @override
  Future<SceneEntityPosition?> getEntityPosition({
    required String sceneMapId,
    required String entityType,
    required String entityId,
  }) async =>
      _positions[_positionKey(sceneMapId, entityType, entityId)];

  @override
  Future<List<SceneEntityPosition>> getEntityPositionsForMap(
    String sceneMapId,
  ) async =>
      _positions.values
          .where((position) => position.sceneMapId == sceneMapId)
          .toList(growable: false);

  @override
  Future<void> saveEntityPosition(SceneEntityPosition position) async {
    _positions[_positionKey(
      position.sceneMapId,
      position.entityType,
      position.entityId,
    )] = position;
  }
}

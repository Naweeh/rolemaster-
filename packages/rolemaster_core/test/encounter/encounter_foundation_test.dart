import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 8, 10, 21);

  test('Encounter enforces unique participant references', () {
    expect(
      () => Encounter(
        id: 'enc-1',
        campaignId: 'campaign-1',
        name: 'Ambush',
        participants: <EncounterParticipant>[
          EncounterParticipant(entityType: 'npc', entityId: 'npc-1'),
          EncounterParticipant(entityType: 'NPC', entityId: 'npc-1'),
        ],
        createdAt: createdAt,
      ),
      throwsArgumentError,
    );
  });

  test('CreateEncounter derives world/location from scene map', () async {
    final campaigns = _CampaignRepo(<Campaign>[
      Campaign(
        id: 'campaign-1',
        name: 'Campaign',
        createdAt: createdAt,
      ),
    ]);
    final worlds = _WorldRepo(
      worlds: <World>[
        World(
          id: 'world-1',
          campaignId: 'campaign-1',
          name: 'World',
          createdAt: createdAt,
        ),
      ],
      locations: <Location>[
        Location(
          id: 'location-1',
          worldId: 'world-1',
          name: 'Ruins',
          createdAt: createdAt,
        ),
      ],
    );
    final maps = _SceneMapRepo(<SceneMap>[
      SceneMap(
        id: 'map-1',
        campaignId: 'campaign-1',
        name: 'Ruins Map',
        worldId: 'world-1',
        locationId: 'location-1',
        coordinateSpace: SceneCoordinateSpace(width: 100, height: 100),
        createdAt: createdAt,
      ),
    ]);
    final encounters = _EncounterRepo();

    final create = CreateEncounter(
      repository: encounters,
      campaignRepository: campaigns,
      worldRepository: worlds,
      sceneMapRepository: maps,
      idGenerator: () => 'enc-1',
      clock: () => createdAt,
    );

    final encounter = await create(
      campaignId: 'campaign-1',
      name: 'Ruins encounter',
      sceneMapId: 'map-1',
    );

    expect(encounter.status, EncounterStatus.planned);
    expect(encounter.worldId, 'world-1');
    expect(encounter.locationId, 'location-1');
    expect(encounter.sceneMapId, 'map-1');
    expect((await encounters.getById('enc-1'))?.name, 'Ruins encounter');
  });

  test('CreateEncounter rejects a scene map from another campaign', () async {
    final campaigns = _CampaignRepo(<Campaign>[
      Campaign(
        id: 'campaign-1',
        name: 'Campaign',
        createdAt: createdAt,
      ),
    ]);
    final maps = _SceneMapRepo(<SceneMap>[
      SceneMap(
        id: 'foreign-map',
        campaignId: 'campaign-2',
        name: 'Foreign',
        coordinateSpace: SceneCoordinateSpace(width: 10, height: 10),
        createdAt: createdAt,
      ),
    ]);

    final create = CreateEncounter(
      repository: _EncounterRepo(),
      campaignRepository: campaigns,
      worldRepository: _WorldRepo(),
      sceneMapRepository: maps,
      idGenerator: () => 'enc-1',
      clock: () => createdAt,
    );

    expect(
      () => create(
        campaignId: 'campaign-1',
        name: 'Invalid',
        sceneMapId: 'foreign-map',
      ),
      throwsA(isA<EncounterContextException>()),
    );
  });

  test('participants and lifecycle persist through use cases', () async {
    final repository = _EncounterRepo();
    await repository.save(
      Encounter(
        id: 'enc-1',
        campaignId: 'campaign-1',
        name: 'Road encounter',
        createdAt: createdAt,
      ),
    );

    var now = createdAt.add(const Duration(minutes: 1));
    final add = AddEncounterParticipant(
      repository: repository,
      clock: () => now,
    );
    final start = StartEncounter(repository: repository, clock: () => now);
    final close = CloseEncounter(repository: repository, clock: () => now);

    var encounter = await add(
      encounterId: 'enc-1',
      entityType: 'character',
      entityId: 'pc-1',
      label: 'Aldren',
    );
    expect(encounter.participants.single.label, 'Aldren');

    expect(
      () => add(
        encounterId: 'enc-1',
        entityType: 'CHARACTER',
        entityId: 'pc-1',
      ),
      throwsStateError,
    );

    now = now.add(const Duration(minutes: 1));
    encounter = await start('enc-1');
    expect(encounter.status, EncounterStatus.active);
    expect(encounter.startedAt, now);

    now = now.add(const Duration(minutes: 1));
    encounter = await close('enc-1');
    expect(encounter.status, EncounterStatus.closed);
    expect(encounter.closedAt, now);

    expect(
      () => add(
        encounterId: 'enc-1',
        entityType: 'npc',
        entityId: 'npc-1',
      ),
      throwsStateError,
    );
  });

  test('RemoveEncounterParticipant removes an existing reference', () async {
    final repository = _EncounterRepo();
    await repository.save(
      Encounter(
        id: 'enc-1',
        campaignId: 'campaign-1',
        name: 'Road encounter',
        participants: <EncounterParticipant>[
          EncounterParticipant(entityType: 'npc', entityId: 'npc-1'),
        ],
        createdAt: createdAt,
      ),
    );

    final remove = RemoveEncounterParticipant(
      repository: repository,
      clock: () => createdAt.add(const Duration(minutes: 1)),
    );
    final updated = await remove(
      encounterId: 'enc-1',
      entityType: 'NPC',
      entityId: 'npc-1',
    );

    expect(updated.participants, isEmpty);
  });

  test('ListEncounters forwards optional status filter', () async {
    final repository = _EncounterRepo();
    await repository.save(
      Encounter(
        id: 'planned',
        campaignId: 'campaign-1',
        name: 'Planned',
        createdAt: createdAt,
      ),
    );
    await repository.save(
      Encounter(
        id: 'active',
        campaignId: 'campaign-1',
        name: 'Active',
        status: EncounterStatus.active,
        createdAt: createdAt,
        updatedAt: createdAt.add(const Duration(minutes: 1)),
        startedAt: createdAt.add(const Duration(minutes: 1)),
      ),
    );

    final list = ListEncounters(repository);
    final active = await list('campaign-1', status: EncounterStatus.active);

    expect(active.map((item) => item.id), <String>['active']);
  });
}

final class _EncounterRepo implements EncounterRepository {
  final Map<String, Encounter> _items = <String, Encounter>{};

  @override
  Future<Encounter?> getById(String id) async => _items[id];

  @override
  Future<List<Encounter>> getForCampaign(
    String campaignId, {
    EncounterStatus? status,
  }) async {
    return _items.values
        .where(
          (item) =>
              item.campaignId == campaignId &&
              (status == null || item.status == status),
        )
        .toList(growable: false);
  }

  @override
  Future<void> save(Encounter encounter) async {
    _items[encounter.id] = encounter;
  }
}

final class _CampaignRepo implements CampaignRepository {
  _CampaignRepo(Iterable<Campaign> campaigns)
      : _items = <String, Campaign>{
          for (final campaign in campaigns) campaign.id: campaign,
        };

  final Map<String, Campaign> _items;

  @override
  Future<Campaign?> getById(String id) async => _items[id];

  @override
  Future<List<Campaign>> getAll({bool includeArchived = false}) async {
    return _items.values
        .where((item) => includeArchived || !item.isArchived)
        .toList(growable: false);
  }

  @override
  Future<void> save(Campaign campaign) async {
    _items[campaign.id] = campaign;
  }
}

final class _WorldRepo implements WorldRepository {
  _WorldRepo({
    Iterable<World> worlds = const <World>[],
    Iterable<Location> locations = const <Location>[],
  })  : _worlds = <String, World>{for (final world in worlds) world.id: world},
        _locations = <String, Location>{
          for (final location in locations) location.id: location,
        };

  final Map<String, World> _worlds;
  final Map<String, Location> _locations;
  final Map<String, Region> _regions = <String, Region>{};

  @override
  Future<World?> getWorldById(String id) async => _worlds[id];

  @override
  Future<List<World>> getWorldsForCampaign(String campaignId) async =>
      _worlds.values
          .where((item) => item.campaignId == campaignId)
          .toList(growable: false);

  @override
  Future<void> saveWorld(World world) async => _worlds[world.id] = world;

  @override
  Future<Region?> getRegionById(String id) async => _regions[id];

  @override
  Future<List<Region>> getRegionsForWorld(String worldId) async =>
      _regions.values
          .where((item) => item.worldId == worldId)
          .toList(growable: false);

  @override
  Future<void> saveRegion(Region region) async => _regions[region.id] = region;

  @override
  Future<Location?> getLocationById(String id) async => _locations[id];

  @override
  Future<List<Location>> getLocationsForWorld(String worldId) async =>
      _locations.values
          .where((item) => item.worldId == worldId)
          .toList(growable: false);

  @override
  Future<void> saveLocation(Location location) async =>
      _locations[location.id] = location;
}

final class _SceneMapRepo implements SceneMapRepository {
  _SceneMapRepo([Iterable<SceneMap> maps = const <SceneMap>[]])
      : _maps = <String, SceneMap>{for (final map in maps) map.id: map};

  final Map<String, SceneMap> _maps;
  final Map<String, SceneLayer> _layers = <String, SceneLayer>{};
  final Map<String, SceneEntityPosition> _positions =
      <String, SceneEntityPosition>{};

  @override
  Future<SceneMap?> getMapById(String id) async => _maps[id];

  @override
  Future<List<SceneMap>> getMapsForCampaign(String campaignId) async =>
      _maps.values
          .where((item) => item.campaignId == campaignId)
          .toList(growable: false);

  @override
  Future<void> saveMap(SceneMap map) async => _maps[map.id] = map;

  @override
  Future<SceneLayer?> getLayerById(String id) async => _layers[id];

  @override
  Future<List<SceneLayer>> getLayersForMap(String sceneMapId) async =>
      _layers.values
          .where((item) => item.sceneMapId == sceneMapId)
          .toList(growable: false);

  @override
  Future<void> saveLayer(SceneLayer layer) async => _layers[layer.id] = layer;

  @override
  Future<SceneEntityPosition?> getEntityPosition({
    required String sceneMapId,
    required String entityType,
    required String entityId,
  }) async {
    return _positions['$sceneMapId:$entityType:$entityId'];
  }

  @override
  Future<List<SceneEntityPosition>> getEntityPositionsForMap(
    String sceneMapId,
  ) async {
    return _positions.values
        .where((item) => item.sceneMapId == sceneMapId)
        .toList(growable: false);
  }

  @override
  Future<void> saveEntityPosition(SceneEntityPosition position) async {
    _positions[
            '${position.sceneMapId}:${position.entityType}:${position.entityId}'] =
        position;
  }
}

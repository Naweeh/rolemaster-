import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteSceneMapRepository', () {
    test('persists map, layers and entity positions after reopening', () async {
      final fixture = await _fixture('map-reopen', withWorld: true);
      addTearDown(fixture.dispose);

      final writer = SqliteSceneMapRepository.open(fixture.path);
      await writer.saveMap(_map(world: true));
      await writer.saveLayer(
        SceneLayer(
          id: 'layer-1',
          sceneMapId: 'map-1',
          name: 'Tokens',
          orderIndex: 0,
          visibility: SceneLayerVisibility.shared,
        ),
      );
      await writer.saveEntityPosition(
        SceneEntityPosition(
          sceneMapId: 'map-1',
          entityType: 'npc',
          entityId: 'npc-1',
          x: 22.5,
          y: 30,
          layerId: 'layer-1',
          updatedAt: DateTime.utc(2026, 8, 10, 20),
        ),
      );
      writer.close();

      final reader = SqliteSceneMapRepository.open(fixture.path);
      final map = await reader.getMapById('map-1');
      final layers = await reader.getLayersForMap('map-1');
      final position = await reader.getEntityPosition(
        sceneMapId: 'map-1',
        entityType: 'npc',
        entityId: 'npc-1',
      );
      reader.close();

      expect(map, isNotNull);
      expect(map!.locationId, 'location-1');
      expect(map.coordinateSpace.width, 100);
      expect(layers.single.visibility, SceneLayerVisibility.shared);
      expect(position, isNotNull);
      expect(position!.layerId, 'layer-1');
      expect(position.x, 22.5);
    });

    test('database rejects a position using a layer from another map', () async {
      final fixture = await _fixture('map-layer-fk');
      addTearDown(fixture.dispose);
      final repository = SqliteSceneMapRepository.open(fixture.path);
      addTearDown(repository.close);

      await repository.saveMap(_map());
      await repository.saveMap(
        SceneMap(
          id: 'map-2',
          campaignId: 'campaign-1',
          name: 'Segundo',
          coordinateSpace: SceneCoordinateSpace(width: 50, height: 50),
          createdAt: DateTime.utc(2026, 8, 10, 19),
        ),
      );
      await repository.saveLayer(
        SceneLayer(
          id: 'layer-2',
          sceneMapId: 'map-2',
          name: 'Otra',
          orderIndex: 0,
        ),
      );

      await expectLater(
        repository.saveEntityPosition(
          SceneEntityPosition(
            sceneMapId: 'map-1',
            entityType: 'character',
            entityId: 'character-1',
            x: 10,
            y: 10,
            layerId: 'layer-2',
            updatedAt: DateTime.utc(2026, 8, 10, 20),
          ),
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('migrates v12 to v13 without losing inventory', () async {
      final fixture = await _fixture('map-migration', withItem: true);
      addTearDown(fixture.dispose);

      final legacy = sqlite3.open(fixture.path);
      legacy.execute('DROP TABLE scene_entity_positions');
      legacy.execute('DROP TABLE scene_layers');
      legacy.execute('DROP TABLE scene_maps');
      legacy.execute('PRAGMA user_version = 12');
      legacy.close();

      final maps = SqliteSceneMapRepository.open(fixture.path);
      await maps.saveMap(_map());
      maps.close();

      final items = SqliteItemInstanceRepository.open(fixture.path);
      final item = await items.getById('item-1');
      items.close();
      final database = sqlite3.open(fixture.path);
      final version = database.select('PRAGMA user_version').single;
      database.close();

      expect(version['user_version'], SqliteSceneMapRepository.schemaVersion);
      expect(item, isNotNull);
      expect(item!.customName, 'Llave');
    });
  });
}

SceneMap _map({bool world = false}) => SceneMap(
      id: 'map-1',
      campaignId: 'campaign-1',
      name: 'Escena',
      worldId: world ? 'world-1' : null,
      locationId: world ? 'location-1' : null,
      coordinateSpace: SceneCoordinateSpace(width: 100, height: 80),
      createdAt: DateTime.utc(2026, 8, 10, 18),
    );

Future<_Fixture> _fixture(
  String prefix, {
  bool withWorld = false,
  bool withItem = false,
}) async {
  final directory = await Directory.systemTemp.createTemp('rolemaster_$prefix');
  final path = '${directory.path}${Platform.pathSeparator}rolemaster.db';
  final campaigns = SqliteCampaignRepository.open(path);
  await campaigns.save(
    Campaign(
      id: 'campaign-1',
      name: 'Campaña',
      createdAt: DateTime.utc(2026, 8, 10, 10),
    ),
  );
  campaigns.close();

  if (withWorld) {
    final worlds = SqliteWorldRepository.open(path);
    await worlds.saveWorld(
      World(
        id: 'world-1',
        campaignId: 'campaign-1',
        name: 'Mundo',
        createdAt: DateTime.utc(2026, 8, 10, 11),
      ),
    );
    await worlds.saveLocation(
      Location(
        id: 'location-1',
        worldId: 'world-1',
        name: 'Posada',
        createdAt: DateTime.utc(2026, 8, 10, 12),
      ),
    );
    worlds.close();
  }

  if (withItem) {
    final items = SqliteItemInstanceRepository.open(path);
    await items.save(
      ItemInstance(
        id: 'item-1',
        campaignId: 'campaign-1',
        customName: 'Llave',
        createdAt: DateTime.utc(2026, 8, 10, 13),
      ),
    );
    items.close();
  }

  return _Fixture(path: path, directory: directory);
}

final class _Fixture {
  const _Fixture({required this.path, required this.directory});

  final String path;
  final Directory directory;

  Future<void> dispose() => directory.delete(recursive: true);
}

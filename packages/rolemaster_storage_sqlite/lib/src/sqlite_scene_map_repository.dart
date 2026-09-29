import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_operation_logger.dart';
import 'sqlite_schema.dart';

final class SqliteSceneMapRepository implements SceneMapRepository {
  SqliteSceneMapRepository._(this._database) {
    initializeRolemasterSqliteSchema(_database);
  }

  factory SqliteSceneMapRepository.open(String path) {
    return SqliteSceneMapRepository._(sqlite3.open(path));
  }

  factory SqliteSceneMapRepository.inMemory() {
    return SqliteSceneMapRepository._(sqlite3.openInMemory());
  }

  static const int schemaVersion = rolemasterSqliteSchemaVersion;

  final Database _database;

  @override
  Future<SceneMap?> getMapById(String id) async {
    final rows = _database.loggedSelect(
      '''
      SELECT id, campaign_id, name, world_id, location_id,
             logical_width, logical_height, notes, created_at, updated_at
      FROM scene_maps
      WHERE id = ?
      LIMIT 1
      ''',
      <Object?>[id.trim()],
    );
    return rows.isEmpty ? null : _mapFromRow(rows.single);
  }

  @override
  Future<List<SceneMap>> getMapsForCampaign(String campaignId) async {
    final rows = _database.loggedSelect(
      '''
      SELECT id, campaign_id, name, world_id, location_id,
             logical_width, logical_height, notes, created_at, updated_at
      FROM scene_maps
      WHERE campaign_id = ?
      ORDER BY created_at, id
      ''',
      <Object?>[campaignId.trim()],
    );
    return rows.map(_mapFromRow).toList(growable: false);
  }

  @override
  Future<void> saveMap(SceneMap map) async {
    _database.loggedExecute(
      '''
      INSERT INTO scene_maps (
        id, campaign_id, name, world_id, location_id,
        logical_width, logical_height, notes, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        world_id = excluded.world_id,
        location_id = excluded.location_id,
        logical_width = excluded.logical_width,
        logical_height = excluded.logical_height,
        notes = excluded.notes,
        updated_at = excluded.updated_at
      ''',
      <Object?>[
        map.id,
        map.campaignId,
        map.name,
        map.worldId,
        map.locationId,
        map.coordinateSpace.width,
        map.coordinateSpace.height,
        map.notes,
        map.createdAt.millisecondsSinceEpoch,
        map.updatedAt.millisecondsSinceEpoch,
      ],
    );
  }

  @override
  Future<SceneLayer?> getLayerById(String id) async {
    final rows = _database.loggedSelect(
      '''
      SELECT id, scene_map_id, name, order_index, visibility
      FROM scene_layers
      WHERE id = ?
      LIMIT 1
      ''',
      <Object?>[id.trim()],
    );
    return rows.isEmpty ? null : _layerFromRow(rows.single);
  }

  @override
  Future<List<SceneLayer>> getLayersForMap(String sceneMapId) async {
    final rows = _database.loggedSelect(
      '''
      SELECT id, scene_map_id, name, order_index, visibility
      FROM scene_layers
      WHERE scene_map_id = ?
      ORDER BY order_index, id
      ''',
      <Object?>[sceneMapId.trim()],
    );
    return rows.map(_layerFromRow).toList(growable: false);
  }

  @override
  Future<void> saveLayer(SceneLayer layer) async {
    _database.loggedExecute(
      '''
      INSERT INTO scene_layers (
        id, scene_map_id, name, order_index, visibility
      ) VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        order_index = excluded.order_index,
        visibility = excluded.visibility
      ''',
      <Object?>[
        layer.id,
        layer.sceneMapId,
        layer.name,
        layer.orderIndex,
        layer.visibility.name,
      ],
    );
  }

  @override
  Future<SceneEntityPosition?> getEntityPosition({
    required String sceneMapId,
    required String entityType,
    required String entityId,
  }) async {
    final rows = _database.loggedSelect(
      '''
      SELECT scene_map_id, entity_type, entity_id, x, y, layer_id, updated_at
      FROM scene_entity_positions
      WHERE scene_map_id = ? AND entity_type = ? AND entity_id = ?
      LIMIT 1
      ''',
      <Object?>[sceneMapId.trim(), entityType.trim(), entityId.trim()],
    );
    return rows.isEmpty ? null : _positionFromRow(rows.single);
  }

  @override
  Future<List<SceneEntityPosition>> getEntityPositionsForMap(
    String sceneMapId,
  ) async {
    final rows = _database.loggedSelect(
      '''
      SELECT scene_map_id, entity_type, entity_id, x, y, layer_id, updated_at
      FROM scene_entity_positions
      WHERE scene_map_id = ?
      ORDER BY entity_type, entity_id
      ''',
      <Object?>[sceneMapId.trim()],
    );
    return rows.map(_positionFromRow).toList(growable: false);
  }

  @override
  Future<void> saveEntityPosition(SceneEntityPosition position) async {
    _database.loggedExecute(
      '''
      INSERT INTO scene_entity_positions (
        scene_map_id, entity_type, entity_id, x, y, layer_id, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(scene_map_id, entity_type, entity_id) DO UPDATE SET
        x = excluded.x,
        y = excluded.y,
        layer_id = excluded.layer_id,
        updated_at = excluded.updated_at
      ''',
      <Object?>[
        position.sceneMapId,
        position.entityType,
        position.entityId,
        position.x,
        position.y,
        position.layerId,
        position.updatedAt.millisecondsSinceEpoch,
      ],
    );
  }

  void close() {
    _database.close();
  }

  SceneMap _mapFromRow(Row row) {
    return SceneMap(
      id: row['id'] as String,
      campaignId: row['campaign_id'] as String,
      name: row['name'] as String,
      worldId: row['world_id'] as String?,
      locationId: row['location_id'] as String?,
      coordinateSpace: SceneCoordinateSpace(
        width: (row['logical_width'] as num).toDouble(),
        height: (row['logical_height'] as num).toDouble(),
      ),
      notes: row['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at'] as int,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at'] as int,
        isUtc: true,
      ),
    );
  }

  SceneLayer _layerFromRow(Row row) {
    return SceneLayer(
      id: row['id'] as String,
      sceneMapId: row['scene_map_id'] as String,
      name: row['name'] as String,
      orderIndex: row['order_index'] as int,
      visibility: SceneLayerVisibility.values.byName(
        row['visibility'] as String,
      ),
    );
  }

  SceneEntityPosition _positionFromRow(Row row) {
    return SceneEntityPosition(
      sceneMapId: row['scene_map_id'] as String,
      entityType: row['entity_type'] as String,
      entityId: row['entity_id'] as String,
      x: (row['x'] as num).toDouble(),
      y: (row['y'] as num).toDouble(),
      layerId: row['layer_id'] as String?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at'] as int,
        isUtc: true,
      ),
    );
  }
}

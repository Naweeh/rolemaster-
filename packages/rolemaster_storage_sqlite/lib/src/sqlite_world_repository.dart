import 'dart:convert';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_schema.dart';

final class SqliteWorldRepository implements WorldRepository {
  SqliteWorldRepository._(this._database) {
    initializeRolemasterSqliteSchema(_database);
  }

  factory SqliteWorldRepository.open(String path) {
    return SqliteWorldRepository._(sqlite3.open(path));
  }

  factory SqliteWorldRepository.inMemory() {
    return SqliteWorldRepository._(sqlite3.openInMemory());
  }

  static const int schemaVersion = rolemasterSqliteSchemaVersion;

  final Database _database;

  @override
  Future<World?> getWorldById(String id) async {
    final rows = _database.select(
      '''
      SELECT id, campaign_id, name, created_at, updated_at, description, tags_json
      FROM worlds
      WHERE id = ?
      LIMIT 1
      ''',
      <Object?>[id.trim()],
    );
    return rows.isEmpty ? null : _worldFromRow(rows.single);
  }

  @override
  Future<List<World>> getWorldsForCampaign(String campaignId) async {
    final rows = _database.select(
      '''
      SELECT id, campaign_id, name, created_at, updated_at, description, tags_json
      FROM worlds
      WHERE campaign_id = ?
      ORDER BY updated_at DESC, id ASC
      ''',
      <Object?>[campaignId.trim()],
    );
    return rows.map(_worldFromRow).toList(growable: false);
  }

  @override
  Future<void> saveWorld(World world) async {
    _database.execute(
      '''
      INSERT INTO worlds (
        id, campaign_id, name, created_at, updated_at, description, tags_json
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        campaign_id = excluded.campaign_id,
        name = excluded.name,
        created_at = excluded.created_at,
        updated_at = excluded.updated_at,
        description = excluded.description,
        tags_json = excluded.tags_json
      ''',
      <Object?>[
        world.id,
        world.campaignId,
        world.name,
        world.createdAt.millisecondsSinceEpoch,
        world.updatedAt.millisecondsSinceEpoch,
        world.metadata.description,
        jsonEncode(world.metadata.tags),
      ],
    );
  }

  @override
  Future<Region?> getRegionById(String id) async {
    final rows = _database.select(
      '''
      SELECT
        id,
        world_id,
        name,
        parent_region_id,
        created_at,
        updated_at,
        description,
        tags_json
      FROM regions
      WHERE id = ?
      LIMIT 1
      ''',
      <Object?>[id.trim()],
    );
    return rows.isEmpty ? null : _regionFromRow(rows.single);
  }

  @override
  Future<List<Region>> getRegionsForWorld(String worldId) async {
    final rows = _database.select(
      '''
      SELECT
        id,
        world_id,
        name,
        parent_region_id,
        created_at,
        updated_at,
        description,
        tags_json
      FROM regions
      WHERE world_id = ?
      ORDER BY name COLLATE NOCASE ASC, id ASC
      ''',
      <Object?>[worldId.trim()],
    );
    return rows.map(_regionFromRow).toList(growable: false);
  }

  @override
  Future<void> saveRegion(Region region) async {
    _database.execute(
      '''
      INSERT INTO regions (
        id,
        world_id,
        name,
        parent_region_id,
        created_at,
        updated_at,
        description,
        tags_json
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        world_id = excluded.world_id,
        name = excluded.name,
        parent_region_id = excluded.parent_region_id,
        created_at = excluded.created_at,
        updated_at = excluded.updated_at,
        description = excluded.description,
        tags_json = excluded.tags_json
      ''',
      <Object?>[
        region.id,
        region.worldId,
        region.name,
        region.parentRegionId,
        region.createdAt.millisecondsSinceEpoch,
        region.updatedAt.millisecondsSinceEpoch,
        region.metadata.description,
        jsonEncode(region.metadata.tags),
      ],
    );
  }

  @override
  Future<Location?> getLocationById(String id) async {
    final rows = _database.select(
      '''
      SELECT
        id,
        world_id,
        name,
        region_id,
        parent_location_id,
        created_at,
        updated_at,
        description,
        tags_json
      FROM locations
      WHERE id = ?
      LIMIT 1
      ''',
      <Object?>[id.trim()],
    );
    return rows.isEmpty ? null : _locationFromRow(rows.single);
  }

  @override
  Future<List<Location>> getLocationsForWorld(String worldId) async {
    final rows = _database.select(
      '''
      SELECT
        id,
        world_id,
        name,
        region_id,
        parent_location_id,
        created_at,
        updated_at,
        description,
        tags_json
      FROM locations
      WHERE world_id = ?
      ORDER BY name COLLATE NOCASE ASC, id ASC
      ''',
      <Object?>[worldId.trim()],
    );
    return rows.map(_locationFromRow).toList(growable: false);
  }

  @override
  Future<void> saveLocation(Location location) async {
    _database.execute(
      '''
      INSERT INTO locations (
        id,
        world_id,
        name,
        region_id,
        parent_location_id,
        created_at,
        updated_at,
        description,
        tags_json
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        world_id = excluded.world_id,
        name = excluded.name,
        region_id = excluded.region_id,
        parent_location_id = excluded.parent_location_id,
        created_at = excluded.created_at,
        updated_at = excluded.updated_at,
        description = excluded.description,
        tags_json = excluded.tags_json
      ''',
      <Object?>[
        location.id,
        location.worldId,
        location.name,
        location.regionId,
        location.parentLocationId,
        location.createdAt.millisecondsSinceEpoch,
        location.updatedAt.millisecondsSinceEpoch,
        location.metadata.description,
        jsonEncode(location.metadata.tags),
      ],
    );
  }

  void close() {
    _database.close();
  }

  World _worldFromRow(Row row) {
    return World(
      id: row['id'] as String,
      campaignId: row['campaign_id'] as String,
      name: row['name'] as String,
      createdAt: _dateFromRow(row, 'created_at'),
      updatedAt: _dateFromRow(row, 'updated_at'),
      metadata: _metadataFromRow(row),
    );
  }

  Region _regionFromRow(Row row) {
    return Region(
      id: row['id'] as String,
      worldId: row['world_id'] as String,
      name: row['name'] as String,
      parentRegionId: row['parent_region_id'] as String?,
      createdAt: _dateFromRow(row, 'created_at'),
      updatedAt: _dateFromRow(row, 'updated_at'),
      metadata: _metadataFromRow(row),
    );
  }

  Location _locationFromRow(Row row) {
    return Location(
      id: row['id'] as String,
      worldId: row['world_id'] as String,
      name: row['name'] as String,
      regionId: row['region_id'] as String?,
      parentLocationId: row['parent_location_id'] as String?,
      createdAt: _dateFromRow(row, 'created_at'),
      updatedAt: _dateFromRow(row, 'updated_at'),
      metadata: _metadataFromRow(row),
    );
  }

  DateTime _dateFromRow(Row row, String column) {
    return DateTime.fromMillisecondsSinceEpoch(
      row[column] as int,
      isUtc: true,
    );
  }

  WorldMetadata _metadataFromRow(Row row) {
    return WorldMetadata(
      description: row['description'] as String?,
      tags: _decodeTags(row['tags_json'] as String),
    );
  }

  List<String> _decodeTags(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! List || decoded.any((value) => value is! String)) {
      throw StateError('Invalid World tags payload in Rolemaster database.');
    }
    return decoded.cast<String>();
  }
}

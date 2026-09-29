import 'dart:convert';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_operation_logger.dart';
import 'sqlite_schema.dart';

final class SqliteCreatureRepository implements CreatureRepository {
  SqliteCreatureRepository._(this._database) {
    initializeRolemasterSqliteSchema(_database);
  }

  factory SqliteCreatureRepository.open(String path) {
    return SqliteCreatureRepository._(sqlite3.open(path));
  }

  factory SqliteCreatureRepository.inMemory() {
    return SqliteCreatureRepository._(sqlite3.openInMemory());
  }

  static const int schemaVersion = rolemasterSqliteSchemaVersion;

  final Database _database;

  @override
  Future<Creature?> getById(String id) async {
    final rows = _database.loggedSelect(
      '''
      SELECT
        id,
        campaign_id,
        name,
        created_at,
        updated_at,
        archived_at,
        world_id,
        location_id,
        species,
        category,
        description,
        notes,
        tags_json
      FROM creatures
      WHERE id = ?
      LIMIT 1
      ''',
      <Object?>[id.trim()],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _creatureFromRow(rows.single);
  }

  @override
  Future<List<Creature>> getForCampaign(
    String campaignId, {
    bool includeArchived = false,
  }) async {
    final normalizedCampaignId = campaignId.trim();
    if (normalizedCampaignId.isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'Creature campaignId cannot be empty.',
      );
    }

    final archivedClause = includeArchived ? '' : 'AND archived_at IS NULL';
    final rows = _database.loggedSelect(
      '''
      SELECT
        id,
        campaign_id,
        name,
        created_at,
        updated_at,
        archived_at,
        world_id,
        location_id,
        species,
        category,
        description,
        notes,
        tags_json
      FROM creatures
      WHERE campaign_id = ? $archivedClause
      ORDER BY updated_at DESC, id ASC
      ''',
      <Object?>[normalizedCampaignId],
    );
    return rows.map(_creatureFromRow).toList(growable: false);
  }

  @override
  Future<void> save(Creature creature) async {
    _database.loggedExecute(
      '''
      INSERT INTO creatures (
        id,
        campaign_id,
        name,
        created_at,
        updated_at,
        archived_at,
        world_id,
        location_id,
        species,
        category,
        description,
        notes,
        tags_json
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        campaign_id = excluded.campaign_id,
        name = excluded.name,
        created_at = excluded.created_at,
        updated_at = excluded.updated_at,
        archived_at = excluded.archived_at,
        world_id = excluded.world_id,
        location_id = excluded.location_id,
        species = excluded.species,
        category = excluded.category,
        description = excluded.description,
        notes = excluded.notes,
        tags_json = excluded.tags_json
      ''',
      <Object?>[
        creature.id,
        creature.campaignId,
        creature.name,
        creature.createdAt.millisecondsSinceEpoch,
        creature.updatedAt.millisecondsSinceEpoch,
        creature.archivedAt?.millisecondsSinceEpoch,
        creature.placement.worldId,
        creature.placement.locationId,
        creature.metadata.species,
        creature.metadata.category,
        creature.metadata.description,
        creature.metadata.notes,
        jsonEncode(creature.metadata.tags),
      ],
    );
  }

  void close() {
    _database.close();
  }

  Creature _creatureFromRow(Row row) {
    final archivedAt = row['archived_at'] as int?;
    return Creature(
      id: row['id'] as String,
      campaignId: row['campaign_id'] as String,
      name: row['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at'] as int,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at'] as int,
        isUtc: true,
      ),
      archivedAt: archivedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(archivedAt, isUtc: true),
      metadata: CreatureMetadata(
        species: row['species'] as String,
        category: row['category'] as String?,
        description: row['description'] as String?,
        notes: row['notes'] as String?,
        tags: _decodeTags(row['tags_json'] as String),
      ),
      placement: CreaturePlacement(
        worldId: row['world_id'] as String?,
        locationId: row['location_id'] as String?,
      ),
    );
  }

  List<String> _decodeTags(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! List || decoded.any((value) => value is! String)) {
      throw StateError('Invalid Creature tags payload in Rolemaster database.');
    }
    return decoded.cast<String>();
  }
}

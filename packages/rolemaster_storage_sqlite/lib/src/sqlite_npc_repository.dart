import 'dart:convert';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_operation_logger.dart';
import 'sqlite_schema.dart';

final class SqliteNpcRepository implements NpcRepository {
  SqliteNpcRepository._(this._database) {
    initializeRolemasterSqliteSchema(_database);
  }

  factory SqliteNpcRepository.open(String path) {
    return SqliteNpcRepository._(sqlite3.open(path));
  }

  factory SqliteNpcRepository.inMemory() {
    return SqliteNpcRepository._(sqlite3.openInMemory());
  }

  static const int schemaVersion = rolemasterSqliteSchemaVersion;

  final Database _database;

  @override
  Future<Npc?> getById(String id) async {
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
        native_language,
        known_languages_json,
        role,
        description,
        notes,
        tags_json
      FROM npcs
      WHERE id = ?
      LIMIT 1
      ''',
      <Object?>[id.trim()],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _npcFromRow(rows.single);
  }

  @override
  Future<List<Npc>> getForCampaign(
    String campaignId, {
    bool includeArchived = false,
  }) async {
    final normalizedCampaignId = campaignId.trim();
    if (normalizedCampaignId.isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'NPC campaignId cannot be empty.',
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
        native_language,
        known_languages_json,
        role,
        description,
        notes,
        tags_json
      FROM npcs
      WHERE campaign_id = ? $archivedClause
      ORDER BY updated_at DESC, id ASC
      ''',
      <Object?>[normalizedCampaignId],
    );
    return rows.map(_npcFromRow).toList(growable: false);
  }

  @override
  Future<void> save(Npc npc) async {
    _database.loggedExecute(
      '''
      INSERT INTO npcs (
        id,
        campaign_id,
        name,
        created_at,
        updated_at,
        archived_at,
        world_id,
        location_id,
        native_language,
        known_languages_json,
        role,
        description,
        notes,
        tags_json
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        campaign_id = excluded.campaign_id,
        name = excluded.name,
        created_at = excluded.created_at,
        updated_at = excluded.updated_at,
        archived_at = excluded.archived_at,
        world_id = excluded.world_id,
        location_id = excluded.location_id,
        native_language = excluded.native_language,
        known_languages_json = excluded.known_languages_json,
        role = excluded.role,
        description = excluded.description,
        notes = excluded.notes,
        tags_json = excluded.tags_json
      ''',
      <Object?>[
        npc.id,
        npc.campaignId,
        npc.name,
        npc.createdAt.millisecondsSinceEpoch,
        npc.updatedAt.millisecondsSinceEpoch,
        npc.archivedAt?.millisecondsSinceEpoch,
        npc.placement.worldId,
        npc.placement.locationId,
        npc.metadata.nativeLanguage,
        jsonEncode(npc.metadata.knownLanguages),
        npc.metadata.role,
        npc.metadata.description,
        npc.metadata.notes,
        jsonEncode(npc.metadata.tags),
      ],
    );
  }

  void close() {
    _database.close();
  }

  Npc _npcFromRow(Row row) {
    final archivedAt = row['archived_at'] as int?;
    final worldId = row['world_id'] as String?;
    final locationId = row['location_id'] as String?;
    return Npc(
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
      metadata: NpcMetadata(
        nativeLanguage: row['native_language'] as String,
        knownLanguages: _decodeStrings(
          row['known_languages_json'] as String,
          fieldName: 'known_languages_json',
        ),
        role: row['role'] as String?,
        description: row['description'] as String?,
        notes: row['notes'] as String?,
        tags: _decodeStrings(
          row['tags_json'] as String,
          fieldName: 'tags_json',
        ),
      ),
      placement: NpcPlacement(worldId: worldId, locationId: locationId),
    );
  }

  List<String> _decodeStrings(String rawJson, {required String fieldName}) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! List || decoded.any((value) => value is! String)) {
      throw StateError(
        'Invalid NPC $fieldName payload in Rolemaster database.',
      );
    }
    return decoded.cast<String>();
  }
}

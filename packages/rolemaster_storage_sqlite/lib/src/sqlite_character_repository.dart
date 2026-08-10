import 'dart:convert';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_schema.dart';

final class SqliteCharacterRepository implements CharacterRepository {
  SqliteCharacterRepository._(this._database) {
    initializeRolemasterSqliteSchema(_database);
  }

  factory SqliteCharacterRepository.open(String path) {
    return SqliteCharacterRepository._(sqlite3.open(path));
  }

  factory SqliteCharacterRepository.inMemory() {
    return SqliteCharacterRepository._(sqlite3.openInMemory());
  }

  static const int schemaVersion = rolemasterSqliteSchemaVersion;

  final Database _database;

  @override
  Future<Character?> getById(String id) async {
    final rows = _database.select(
      '''
      SELECT
        id,
        campaign_id,
        name,
        created_at,
        updated_at,
        archived_at,
        player_name,
        description,
        notes,
        tags_json
      FROM characters
      WHERE id = ?
      LIMIT 1
      ''',
      <Object?>[id.trim()],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _characterFromRow(rows.single);
  }

  @override
  Future<List<Character>> getForCampaign(
    String campaignId, {
    bool includeArchived = false,
  }) async {
    final normalizedCampaignId = campaignId.trim();
    if (normalizedCampaignId.isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'Character campaignId cannot be empty.',
      );
    }

    final archivedClause = includeArchived ? '' : 'AND archived_at IS NULL';
    final rows = _database.select(
      '''
      SELECT
        id,
        campaign_id,
        name,
        created_at,
        updated_at,
        archived_at,
        player_name,
        description,
        notes,
        tags_json
      FROM characters
      WHERE campaign_id = ? $archivedClause
      ORDER BY updated_at DESC, id ASC
      ''',
      <Object?>[normalizedCampaignId],
    );
    return rows.map(_characterFromRow).toList(growable: false);
  }

  @override
  Future<void> save(Character character) async {
    _database.execute(
      '''
      INSERT INTO characters (
        id,
        campaign_id,
        name,
        created_at,
        updated_at,
        archived_at,
        player_name,
        description,
        notes,
        tags_json
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        campaign_id = excluded.campaign_id,
        name = excluded.name,
        created_at = excluded.created_at,
        updated_at = excluded.updated_at,
        archived_at = excluded.archived_at,
        player_name = excluded.player_name,
        description = excluded.description,
        notes = excluded.notes,
        tags_json = excluded.tags_json
      ''',
      <Object?>[
        character.id,
        character.campaignId,
        character.name,
        character.createdAt.millisecondsSinceEpoch,
        character.updatedAt.millisecondsSinceEpoch,
        character.archivedAt?.millisecondsSinceEpoch,
        character.metadata.playerName,
        character.metadata.description,
        character.metadata.notes,
        jsonEncode(character.metadata.tags),
      ],
    );
  }

  void close() {
    _database.close();
  }

  Character _characterFromRow(Row row) {
    final archivedAt = row['archived_at'] as int?;
    return Character(
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
      metadata: CharacterMetadata(
        playerName: row['player_name'] as String?,
        description: row['description'] as String?,
        notes: row['notes'] as String?,
        tags: _decodeTags(row['tags_json'] as String),
      ),
    );
  }

  List<String> _decodeTags(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! List || decoded.any((value) => value is! String)) {
      throw StateError('Invalid Character tags payload in Rolemaster database.');
    }
    return decoded.cast<String>();
  }
}

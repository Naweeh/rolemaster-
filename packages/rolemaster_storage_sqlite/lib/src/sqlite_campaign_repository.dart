import 'dart:convert';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_schema.dart';

final class SqliteCampaignRepository implements CampaignRepository {
  SqliteCampaignRepository._(this._database) {
    initializeRolemasterSqliteSchema(_database);
  }

  factory SqliteCampaignRepository.open(String path) {
    return SqliteCampaignRepository._(sqlite3.open(path));
  }

  factory SqliteCampaignRepository.inMemory() {
    return SqliteCampaignRepository._(sqlite3.openInMemory());
  }

  static const int schemaVersion = rolemasterSqliteSchemaVersion;

  final Database _database;

  @override
  Future<Campaign?> getById(String id) async {
    final rows = _database.select(
      '''
      SELECT
        id,
        name,
        created_at,
        updated_at,
        archived_at,
        description,
        tags_json,
        ai_enabled,
        voice_enabled,
        audio_enabled
      FROM campaigns
      WHERE id = ?
      LIMIT 1
      ''',
      <Object?>[id.trim()],
    );

    if (rows.isEmpty) {
      return null;
    }
    return _campaignFromRow(rows.single);
  }

  @override
  Future<List<Campaign>> getAll({bool includeArchived = false}) async {
    final whereClause = includeArchived ? '' : 'WHERE archived_at IS NULL';
    final rows = _database.select('''
      SELECT
        id,
        name,
        created_at,
        updated_at,
        archived_at,
        description,
        tags_json,
        ai_enabled,
        voice_enabled,
        audio_enabled
      FROM campaigns
      $whereClause
      ORDER BY updated_at DESC, id ASC
      ''');

    return rows.map(_campaignFromRow).toList(growable: false);
  }

  @override
  Future<void> save(Campaign campaign) async {
    _database.execute(
      '''
      INSERT INTO campaigns (
        id,
        name,
        created_at,
        updated_at,
        archived_at,
        description,
        tags_json,
        ai_enabled,
        voice_enabled,
        audio_enabled
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        created_at = excluded.created_at,
        updated_at = excluded.updated_at,
        archived_at = excluded.archived_at,
        description = excluded.description,
        tags_json = excluded.tags_json,
        ai_enabled = excluded.ai_enabled,
        voice_enabled = excluded.voice_enabled,
        audio_enabled = excluded.audio_enabled
      ''',
      <Object?>[
        campaign.id,
        campaign.name,
        campaign.createdAt.millisecondsSinceEpoch,
        campaign.updatedAt.millisecondsSinceEpoch,
        campaign.archivedAt?.millisecondsSinceEpoch,
        campaign.metadata.description,
        jsonEncode(campaign.metadata.tags),
        campaign.configuration.aiEnabled ? 1 : 0,
        campaign.configuration.voiceEnabled ? 1 : 0,
        campaign.configuration.audioEnabled ? 1 : 0,
      ],
    );
  }

  void close() {
    _database.close();
  }

  Campaign _campaignFromRow(Row row) {
    final archivedAt = row['archived_at'] as int?;
    return Campaign(
      id: row['id'] as String,
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
      metadata: CampaignMetadata(
        description: row['description'] as String?,
        tags: _decodeTags(row['tags_json'] as String),
      ),
      configuration: CampaignConfiguration(
        aiEnabled: (row['ai_enabled'] as int) == 1,
        voiceEnabled: (row['voice_enabled'] as int) == 1,
        audioEnabled: (row['audio_enabled'] as int) == 1,
      ),
    );
  }

  List<String> _decodeTags(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! List || decoded.any((value) => value is! String)) {
      throw StateError('Invalid Campaign tags payload in Rolemaster database.');
    }
    return decoded.cast<String>();
  }
}

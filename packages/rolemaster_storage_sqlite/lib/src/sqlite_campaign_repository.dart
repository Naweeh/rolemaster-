import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:sqlite3/sqlite3.dart';

final class SqliteCampaignRepository implements CampaignRepository {
  SqliteCampaignRepository._(this._database) {
    _initializeSchema();
  }

  factory SqliteCampaignRepository.open(String path) {
    return SqliteCampaignRepository._(sqlite3.open(path));
  }

  factory SqliteCampaignRepository.inMemory() {
    return SqliteCampaignRepository._(sqlite3.openInMemory());
  }

  static const int schemaVersion = 1;

  final Database _database;

  @override
  Future<Campaign?> getById(String id) async {
    final rows = _database.select(
      '''
      SELECT id, name, created_at, updated_at, archived_at
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
    final rows = _database.select(
      '''
      SELECT id, name, created_at, updated_at, archived_at
      FROM campaigns
      $whereClause
      ORDER BY updated_at DESC, id ASC
      ''',
    );

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
        archived_at
      ) VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        created_at = excluded.created_at,
        updated_at = excluded.updated_at,
        archived_at = excluded.archived_at
      ''',
      <Object?>[
        campaign.id,
        campaign.name,
        campaign.createdAt.millisecondsSinceEpoch,
        campaign.updatedAt.millisecondsSinceEpoch,
        campaign.archivedAt?.millisecondsSinceEpoch,
      ],
    );
  }

  void close() {
    _database.dispose();
  }

  void _initializeSchema() {
    _database.execute('PRAGMA foreign_keys = ON');

    final versionRows = _database.select('PRAGMA user_version');
    final version = versionRows.single['user_version'] as int;

    if (version == 0) {
      _database.execute('''
        CREATE TABLE campaigns (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          archived_at INTEGER
        ) STRICT
      ''');
      _database.execute('PRAGMA user_version = $schemaVersion');
      return;
    }

    if (version != schemaVersion) {
      throw StateError(
        'Unsupported Rolemaster database schema: $version. '
        'Expected $schemaVersion.',
      );
    }
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
    );
  }
}

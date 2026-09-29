import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_operation_logger.dart';
import 'sqlite_schema.dart';

final class SqliteCampaignStateRepository implements CampaignStateRepository {
  SqliteCampaignStateRepository._(this._database) {
    initializeRolemasterSqliteSchema(_database);
  }

  factory SqliteCampaignStateRepository.open(String path) {
    return SqliteCampaignStateRepository._(sqlite3.open(path));
  }

  factory SqliteCampaignStateRepository.inMemory() {
    return SqliteCampaignStateRepository._(sqlite3.openInMemory());
  }

  static const int schemaVersion = rolemasterSqliteSchemaVersion;

  final Database _database;

  @override
  Future<CampaignState?> getByCampaignId(String campaignId) async {
    final normalizedCampaignId = campaignId.trim();
    if (normalizedCampaignId.isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'Campaign state campaignId cannot be empty.',
      );
    }

    final rows = _database.loggedSelect(
      '''
      SELECT campaign_id, revision, updated_at
      FROM campaign_states
      WHERE campaign_id = ?
      LIMIT 1
      ''',
      <Object?>[normalizedCampaignId],
    );
    if (rows.isEmpty) {
      return null;
    }

    final row = rows.single;
    final updatedAt = row['updated_at'] as int?;
    return CampaignState(
      campaignId: row['campaign_id'] as String,
      revision: row['revision'] as int,
      updatedAt: updatedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(updatedAt, isUtc: true),
    );
  }

  @override
  Future<bool> save(
    CampaignState state, {
    required int expectedRevision,
  }) async {
    if (expectedRevision < 0) {
      throw ArgumentError.value(
        expectedRevision,
        'expectedRevision',
        'Expected revision cannot be negative.',
      );
    }
    if (state.revision != expectedRevision + 1) {
      throw ArgumentError.value(
        state.revision,
        'state.revision',
        'Saved state must advance exactly one revision.',
      );
    }
    final updatedAt = state.updatedAt;
    if (updatedAt == null) {
      throw ArgumentError('Persisted Campaign state requires updatedAt.');
    }

    if (expectedRevision == 0) {
      _database.loggedExecute(
        '''
        INSERT OR IGNORE INTO campaign_states (
          campaign_id,
          revision,
          updated_at
        ) VALUES (?, ?, ?)
        ''',
        <Object?>[
          state.campaignId,
          state.revision,
          updatedAt.millisecondsSinceEpoch,
        ],
      );
      return _changedRows() == 1;
    }

    _database.loggedExecute(
      '''
      UPDATE campaign_states
      SET revision = ?, updated_at = ?
      WHERE campaign_id = ? AND revision = ?
      ''',
      <Object?>[
        state.revision,
        updatedAt.millisecondsSinceEpoch,
        state.campaignId,
        expectedRevision,
      ],
    );
    return _changedRows() == 1;
  }

  void close() {
    _database.close();
  }

  int _changedRows() {
    return _database.loggedSelect('SELECT changes() AS count').single['count']
        as int;
  }
}

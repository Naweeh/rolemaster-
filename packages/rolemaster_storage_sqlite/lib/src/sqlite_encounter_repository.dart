import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_schema.dart';

final class SqliteEncounterRepository implements EncounterRepository {
  SqliteEncounterRepository._(this._database) {
    initializeRolemasterSqliteSchema(_database);
  }

  factory SqliteEncounterRepository.open(String path) {
    return SqliteEncounterRepository._(sqlite3.open(path));
  }

  factory SqliteEncounterRepository.inMemory() {
    return SqliteEncounterRepository._(sqlite3.openInMemory());
  }

  static const int schemaVersion = rolemasterSqliteSchemaVersion;

  final Database _database;

  @override
  Future<Encounter?> getById(String id) async {
    final rows = _database.select(
      '''
      SELECT id, campaign_id, name, status, world_id, location_id, scene_map_id,
             notes, created_at, updated_at, started_at, closed_at
      FROM encounters
      WHERE id = ?
      LIMIT 1
      ''',
      <Object?>[id.trim()],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _encounterFromRow(rows.single);
  }

  @override
  Future<List<Encounter>> getForCampaign(
    String campaignId, {
    EncounterStatus? status,
  }) async {
    final sql = status == null
        ? '''
          SELECT id, campaign_id, name, status, world_id, location_id,
                 scene_map_id, notes, created_at, updated_at, started_at, closed_at
          FROM encounters
          WHERE campaign_id = ?
          ORDER BY created_at, id
          '''
        : '''
          SELECT id, campaign_id, name, status, world_id, location_id,
                 scene_map_id, notes, created_at, updated_at, started_at, closed_at
          FROM encounters
          WHERE campaign_id = ? AND status = ?
          ORDER BY created_at, id
          ''';
    final parameters = status == null
        ? <Object?>[campaignId.trim()]
        : <Object?>[campaignId.trim(), status.name];
    final rows = _database.select(sql, parameters);
    return rows.map(_encounterFromRow).toList(growable: false);
  }

  @override
  Future<void> save(Encounter encounter) async {
    _database.execute('BEGIN IMMEDIATE');
    try {
      _database.execute(
        '''
        INSERT INTO encounters (
          id, campaign_id, name, status, world_id, location_id, scene_map_id,
          notes, created_at, updated_at, started_at, closed_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          name = excluded.name,
          status = excluded.status,
          world_id = excluded.world_id,
          location_id = excluded.location_id,
          scene_map_id = excluded.scene_map_id,
          notes = excluded.notes,
          updated_at = excluded.updated_at,
          started_at = excluded.started_at,
          closed_at = excluded.closed_at
        ''',
        <Object?>[
          encounter.id,
          encounter.campaignId,
          encounter.name,
          encounter.status.name,
          encounter.worldId,
          encounter.locationId,
          encounter.sceneMapId,
          encounter.notes,
          encounter.createdAt.millisecondsSinceEpoch,
          encounter.updatedAt.millisecondsSinceEpoch,
          encounter.startedAt?.millisecondsSinceEpoch,
          encounter.closedAt?.millisecondsSinceEpoch,
        ],
      );

      _database.execute(
        'DELETE FROM encounter_participants WHERE encounter_id = ?',
        <Object?>[encounter.id],
      );
      for (final participant in encounter.participants) {
        _database.execute(
          '''
          INSERT INTO encounter_participants (
            encounter_id, entity_type, entity_id, label
          ) VALUES (?, ?, ?, ?)
          ''',
          <Object?>[
            encounter.id,
            participant.entityType,
            participant.entityId,
            participant.label,
          ],
        );
      }
      _database.execute('COMMIT');
    } catch (_) {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }

  void close() {
    _database.close();
  }

  Encounter _encounterFromRow(Row row) {
    final encounterId = row['id'] as String;
    final participantRows = _database.select(
      '''
      SELECT entity_type, entity_id, label
      FROM encounter_participants
      WHERE encounter_id = ?
      ORDER BY rowid
      ''',
      <Object?>[encounterId],
    );
    final participants = participantRows
        .map(
          (participantRow) => EncounterParticipant(
            entityType: participantRow['entity_type'] as String,
            entityId: participantRow['entity_id'] as String,
            label: participantRow['label'] as String?,
          ),
        )
        .toList(growable: false);

    return Encounter(
      id: encounterId,
      campaignId: row['campaign_id'] as String,
      name: row['name'] as String,
      status: EncounterStatus.values.byName(row['status'] as String),
      participants: participants,
      worldId: row['world_id'] as String?,
      locationId: row['location_id'] as String?,
      sceneMapId: row['scene_map_id'] as String?,
      notes: row['notes'] as String?,
      createdAt: _date(row['created_at'] as int),
      updatedAt: _date(row['updated_at'] as int),
      startedAt: _nullableDate(row['started_at'] as int?),
      closedAt: _nullableDate(row['closed_at'] as int?),
    );
  }
}

DateTime _date(int milliseconds) {
  return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
}

DateTime? _nullableDate(int? milliseconds) {
  return milliseconds == null ? null : _date(milliseconds);
}

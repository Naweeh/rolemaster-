import 'dart:convert';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_operation_logger.dart';
import 'sqlite_schema.dart';

final class SqliteEventHistoryRepository implements EventHistoryRepository {
  SqliteEventHistoryRepository._(this._database) {
    initializeRolemasterSqliteSchema(_database);
  }

  factory SqliteEventHistoryRepository.open(String path) {
    return SqliteEventHistoryRepository._(sqlite3.open(path));
  }

  factory SqliteEventHistoryRepository.inMemory() {
    return SqliteEventHistoryRepository._(sqlite3.openInMemory());
  }

  static const int schemaVersion = rolemasterSqliteSchemaVersion;

  final Database _database;

  @override
  Future<void> append(DomainEvent event) async {
    _database.loggedExecute(
      '''
      INSERT INTO domain_events (
        id,
        type,
        campaign_id,
        occurred_at,
        entity_type,
        entity_id,
        payload_json
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        event.id,
        event.type,
        event.campaignId,
        event.occurredAt.millisecondsSinceEpoch,
        event.entityType,
        event.entityId,
        jsonEncode(event.payload),
      ],
    );
  }

  @override
  Future<DomainEvent?> getById(String id) async {
    final normalizedId = id.trim();
    final rows = _database.loggedSelect(
      '''
      SELECT
        id,
        type,
        campaign_id,
        occurred_at,
        entity_type,
        entity_id,
        payload_json
      FROM domain_events
      WHERE id = ?
      LIMIT 1
      ''',
      <Object?>[normalizedId],
    );
    return rows.isEmpty ? null : _eventFromRow(rows.single);
  }

  @override
  Future<List<DomainEvent>> getForCampaign(
    String campaignId, {
    String? type,
    int? limit,
  }) async {
    final normalizedCampaignId = campaignId.trim();
    if (normalizedCampaignId.isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'Event history campaignId cannot be empty.',
      );
    }
    if (limit != null && limit <= 0) {
      throw ArgumentError.value(
        limit,
        'limit',
        'Event history limit must be positive.',
      );
    }

    final normalizedType = _normalizeOptionalText(type);
    final whereType = normalizedType == null ? '' : 'AND type = ?';
    final parameters = <Object?>[normalizedCampaignId];
    if (normalizedType != null) {
      parameters.add(normalizedType);
    }

    if (limit == null) {
      final rows = _database.loggedSelect('''
        SELECT
          id,
          type,
          campaign_id,
          occurred_at,
          entity_type,
          entity_id,
          payload_json
        FROM domain_events
        WHERE campaign_id = ?
        $whereType
        ORDER BY sequence ASC
        ''', parameters);
      return rows.map(_eventFromRow).toList(growable: false);
    }

    parameters.add(limit);
    final rows = _database.loggedSelect('''
      SELECT
        id,
        type,
        campaign_id,
        occurred_at,
        entity_type,
        entity_id,
        payload_json,
        sequence
      FROM (
        SELECT
          id,
          type,
          campaign_id,
          occurred_at,
          entity_type,
          entity_id,
          payload_json,
          sequence
        FROM domain_events
        WHERE campaign_id = ?
        $whereType
        ORDER BY sequence DESC
        LIMIT ?
      )
      ORDER BY sequence ASC
      ''', parameters);
    return rows.map(_eventFromRow).toList(growable: false);
  }

  void close() {
    _database.close();
  }

  DomainEvent _eventFromRow(Row row) {
    final decoded = jsonDecode(row['payload_json'] as String);
    if (decoded is! Map) {
      throw StateError('Invalid DomainEvent payload in Rolemaster database.');
    }

    final payload = <String, Object?>{};
    for (final entry in decoded.entries) {
      if (entry.key is! String) {
        throw StateError('Invalid DomainEvent payload in Rolemaster database.');
      }
      payload[entry.key as String] = entry.value;
    }

    return DomainEvent(
      id: row['id'] as String,
      type: row['type'] as String,
      campaignId: row['campaign_id'] as String,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(
        row['occurred_at'] as int,
        isUtc: true,
      ),
      entityType: row['entity_type'] as String?,
      entityId: row['entity_id'] as String?,
      payload: payload,
    );
  }

  String? _normalizeOptionalText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

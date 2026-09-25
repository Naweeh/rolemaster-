import 'dart:convert';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_schema.dart';

final class SqliteCombatStateRepository implements CombatStateRepository {
  SqliteCombatStateRepository._(this._database) {
    initializeRolemasterSqliteSchema(_database);
  }

  factory SqliteCombatStateRepository.open(String path) {
    return SqliteCombatStateRepository._(sqlite3.open(path));
  }

  factory SqliteCombatStateRepository.inMemory() {
    return SqliteCombatStateRepository._(sqlite3.openInMemory());
  }

  static const int schemaVersion = rolemasterSqliteSchemaVersion;
  final Database _database;

  @override
  Future<CombatState?> getByEncounterId(String encounterId) async {
    final rows = _database.select(
      'SELECT * FROM combat_states WHERE encounter_id = ?',
      <Object?>[encounterId.trim()],
    );
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.single;
    final order = (jsonDecode(row['turn_order_json'] as String) as List).map((
      item,
    ) {
      final map = Map<String, Object?>.from(item as Map);
      return CombatParticipant(
        entityType: map['entityType'] as String,
        entityId: map['entityId'] as String,
        name: map['name'] as String,
      );
    });
    final actions = (jsonDecode(row['actions_json'] as String) as List).map(
      (item) => _decodeAction(Map<String, Object?>.from(item as Map)),
    );
    return CombatState(
      encounterId: row['encounter_id'] as String,
      campaignId: row['campaign_id'] as String,
      rulesetId: row['ruleset_id'] as String,
      rulesetVersion: row['ruleset_version'] as String,
      revision: row['revision'] as int,
      round: row['round_number'] as int,
      turnIndex: row['turn_index'] as int,
      turnOrder: order,
      actions: actions,
      conditions: (jsonDecode(row['conditions_json'] as String) as List)
          .map((item) {
        final data = Map<String, Object?>.from(item as Map);
        return CombatCondition(
          participantKey: data['participantKey'] as String,
          conditionId: data['conditionId'] as String,
          remainingRounds: data['remainingRounds'] as int?,
          sourceKey: data['sourceKey'] as String?,
        );
      }),
      stats: (jsonDecode(row['stats_json'] as String) as Map).map(
        (key, value) =>
            MapEntry(key as String, Map<String, int>.from(value as Map)),
      ),
    );
  }

  @override
  Future<void> save(CombatState state) async {
    _database.execute('BEGIN IMMEDIATE');
    try {
      final encounterRows = _database.select(
        'SELECT campaign_id, status FROM encounters WHERE id = ?',
        <Object?>[state.encounterId],
      );
      if (encounterRows.isEmpty ||
          encounterRows.single['campaign_id'] != state.campaignId ||
          encounterRows.single['status'] != 'active') {
        throw StateError(
          'Combat requires an active encounter in its campaign.',
        );
      }
      final references = _database.select(
        'SELECT entity_type, entity_id FROM encounter_participants '
        'WHERE encounter_id = ?',
        <Object?>[state.encounterId],
      );
      final keys = references
          .map(
            (row) =>
                '${(row['entity_type'] as String).toLowerCase()}:'
                '${row['entity_id'] as String}',
          )
          .toSet();
      if (keys.length != state.turnOrder.length ||
          !state.turnOrder.every((item) => keys.contains(item.key))) {
        throw StateError('Encounter participants changed during combat.');
      }

      final orderJson = jsonEncode(<Map<String, String>>[
        for (final item in state.turnOrder)
          <String, String>{
            'entityType': item.entityType,
            'entityId': item.entityId,
            'name': item.name,
          },
      ]);
      final actionsJson = jsonEncode(<Map<String, Object?>>[
        for (final action in state.actions) _encodeAction(action),
      ]);

      final statsJson = jsonEncode(state.stats);
      final conditionsJson = jsonEncode(<Map<String, Object?>>[
        for (final condition in state.conditions)
          <String, Object?>{
            'participantKey': condition.participantKey,
            'conditionId': condition.conditionId,
            'remainingRounds': condition.remainingRounds,
            'sourceKey': condition.sourceKey,
          },
      ]);

      if (state.revision == 0) {
        final existing = _database.select(
          'SELECT revision FROM combat_states WHERE encounter_id = ?',
          <Object?>[state.encounterId],
        );
        if (existing.isNotEmpty) {
          throw StateError('Combat state already exists.');
        }
        _database.execute(
          '''INSERT INTO combat_states
             (encounter_id, campaign_id, ruleset_id, ruleset_version,
              revision, round_number, turn_index, turn_order_json, actions_json,
              stats_json, conditions_json)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
          <Object?>[
            state.encounterId,
            state.campaignId,
            state.rulesetId,
            state.rulesetVersion,
            state.revision,
            state.round,
            state.turnIndex,
            orderJson,
            actionsJson,
            statsJson,
            conditionsJson,
          ],
        );
      } else {
        _database.execute(
          '''UPDATE combat_states SET
               revision = ?, round_number = ?, turn_index = ?,
               turn_order_json = ?, actions_json = ?, stats_json = ?, conditions_json = ?
             WHERE encounter_id = ? AND campaign_id = ?
               AND ruleset_id = ? AND ruleset_version = ? AND revision = ?''',
          <Object?>[
            state.revision,
            state.round,
            state.turnIndex,
            orderJson,
            actionsJson,
            statsJson,
            conditionsJson,
            state.encounterId,
            state.campaignId,
            state.rulesetId,
            state.rulesetVersion,
            state.revision - 1,
          ],
        );
        final changed =
            _database.select('SELECT changes() AS count').single['count']
                as int;
        if (changed != 1) {
          throw StateError('Combat state revision conflict.');
        }
      }
      _database.execute('COMMIT');
    } catch (_) {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }

  void close() => _database.close();
}

Map<String, Object?> _encodeAction(CombatAction action) {
  final result = action.result;
  return <String, Object?>{
    'actorKey': action.actorKey,
    'result': <String, Object?>{
      'id': result.id,
      'campaignId': result.campaignId,
      'rulesetId': result.rulesetId,
      'rulesetVersion': result.rulesetVersion,
      'ruleId': result.ruleId,
      'ruleKind': result.ruleKind,
      'outcome': result.outcome,
      'details': result.details,
      'purpose': result.purpose,
      'occurredAt': result.occurredAt.millisecondsSinceEpoch,
      'diceRolls': <Map<String, Object?>>[
        for (final roll in result.diceRolls)
          <String, Object?>{
            'id': roll.id,
            'campaignId': roll.campaignId,
            'rulesetId': roll.rulesetId,
            'rulesetVersion': roll.rulesetVersion,
            'count': roll.formula.count,
            'sides': roll.formula.sides,
            'modifier': roll.formula.modifier,
            'rolls': roll.rolls,
            'purpose': roll.purpose,
            'occurredAt': roll.occurredAt.millisecondsSinceEpoch,
          },
      ],
    },
  };
}

CombatAction _decodeAction(Map<String, Object?> item) {
  final data = Map<String, Object?>.from(item['result'] as Map);
  final rolls = (data['diceRolls'] as List).map((item) {
    final roll = Map<String, Object?>.from(item as Map);
    return DiceRollResult(
      id: roll['id'] as String,
      campaignId: roll['campaignId'] as String,
      rulesetId: roll['rulesetId'] as String,
      rulesetVersion: roll['rulesetVersion'] as String,
      formula: DiceFormula(
        count: roll['count'] as int,
        sides: roll['sides'] as int,
        modifier: roll['modifier'] as int,
      ),
      rolls: (roll['rolls'] as List).cast<int>(),
      purpose: roll['purpose'] as String?,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(
        roll['occurredAt'] as int,
        isUtc: true,
      ),
    );
  });
  return CombatAction(
    actorKey: item['actorKey'] as String,
    result: ResolutionResult(
      id: data['id'] as String,
      campaignId: data['campaignId'] as String,
      rulesetId: data['rulesetId'] as String,
      rulesetVersion: data['rulesetVersion'] as String,
      ruleId: data['ruleId'] as String,
      ruleKind: data['ruleKind'] as String,
      outcome: data['outcome'] as String,
      details: Map<String, Object?>.from(data['details'] as Map),
      diceRolls: rolls,
      purpose: data['purpose'] as String?,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(
        data['occurredAt'] as int,
        isUtc: true,
      ),
    ),
  );
}

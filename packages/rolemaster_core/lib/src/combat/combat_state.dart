import '../resolution/resolution_result.dart';
import 'combat_participant.dart';
import 'ruleset_condition_catalog.dart';

final class CombatAction {
  CombatAction({required String actorKey, required this.result})
      : actorKey = actorKey.trim().toLowerCase() {
    if (this.actorKey.isEmpty) {
      throw ArgumentError('Combat action actorKey is required.');
    }
  }

  final String actorKey;
  final ResolutionResult result;
}

final class CombatState {
  CombatState({
    required String encounterId,
    required String campaignId,
    required String rulesetId,
    required String rulesetVersion,
    required Iterable<CombatParticipant> turnOrder,
    this.revision = 0,
    this.round = 1,
    this.turnIndex = 0,
    Iterable<CombatAction> actions = const <CombatAction>[],
    Map<String, Map<String, int>> stats = const <String, Map<String, int>>{},
    Iterable<CombatCondition> conditions = const <CombatCondition>[],
  })  : encounterId = encounterId.trim(),
        campaignId = campaignId.trim(),
        rulesetId = rulesetId.trim(),
        rulesetVersion = rulesetVersion.trim(),
        turnOrder = List<CombatParticipant>.unmodifiable(turnOrder),
        actions = List<CombatAction>.unmodifiable(actions),
        conditions = List<CombatCondition>.unmodifiable(conditions),
        stats = Map<String, Map<String, int>>.unmodifiable(
          stats.map((key, value) =>
              MapEntry(key, Map<String, int>.unmodifiable(value))),
        ) {
    if (this.encounterId.isEmpty ||
        this.campaignId.isEmpty ||
        this.rulesetId.isEmpty ||
        this.rulesetVersion.isEmpty ||
        revision < 0) {
      throw ArgumentError('Combat encounterId and campaignId are required.');
    }
    if (this.turnOrder.isEmpty ||
        round < 1 ||
        turnIndex < 0 ||
        turnIndex >= this.turnOrder.length) {
      throw ArgumentError('Combat requires participants and a valid turn.');
    }
    if (this.turnOrder.map((item) => item.key).toSet().length !=
        this.turnOrder.length) {
      throw ArgumentError(
          'Combat turn order must contain unique participants.');
    }
    for (final key in this.stats.keys) {
      if (!this.turnOrder.any((item) => item.key == key)) {
        throw ArgumentError('Combat stats belong to an unknown participant.');
      }
    }
    final seenConditions = <String>{};
    for (final condition in this.conditions) {
      if (!this.turnOrder.any((item) => item.key == condition.participantKey) ||
          condition.sourceKey != null &&
              !this.turnOrder.any((item) => item.key == condition.sourceKey) ||
          !seenConditions.add(condition.key)) {
        throw ArgumentError('Invalid or duplicate combat condition.');
      }
    }
    for (final action in this.actions) {
      if (!this.turnOrder.any((item) => item.key == action.actorKey) ||
          action.result.campaignId != this.campaignId ||
          action.result.rulesetId != this.rulesetId ||
          action.result.rulesetVersion != this.rulesetVersion) {
        throw ArgumentError('Combat action does not belong to this combat.');
      }
    }
  }

  final String encounterId;
  final String campaignId;
  final String rulesetId;
  final String rulesetVersion;
  final int revision;
  final List<CombatParticipant> turnOrder;
  final int round;
  final int turnIndex;
  final List<CombatAction> actions;
  final Map<String, Map<String, int>> stats;
  final List<CombatCondition> conditions;

  CombatParticipant get currentParticipant => turnOrder[turnIndex];

  CombatState advanceTurn() {
    final next = turnIndex + 1;
    return CombatState(
      encounterId: encounterId,
      campaignId: campaignId,
      rulesetId: rulesetId,
      rulesetVersion: rulesetVersion,
      revision: revision + 1,
      turnOrder: turnOrder,
      round: next == turnOrder.length ? round + 1 : round,
      turnIndex: next % turnOrder.length,
      actions: actions,
      stats: stats,
      conditions: next == turnOrder.length
          ? conditions.map((item) => item.afterRound()).whereType<CombatCondition>()
          : conditions,
    );
  }

  CombatState addAction(CombatAction action) {
    if (action.actorKey != currentParticipant.key) {
      throw StateError('Only the current participant can act.');
    }
    return CombatState(
      encounterId: encounterId,
      campaignId: campaignId,
      rulesetId: rulesetId,
      rulesetVersion: rulesetVersion,
      revision: revision + 1,
      turnOrder: turnOrder,
      round: round,
      turnIndex: turnIndex,
      actions: <CombatAction>[...actions, action],
      stats: stats,
      conditions: conditions,
    );
  }

  CombatState setStat({
    required String participantKey,
    required String statId,
    required int value,
  }) {
    final key = participantKey.trim().toLowerCase();
    if (!turnOrder.any((item) => item.key == key)) {
      throw StateError('Combat participant not found: $key.');
    }
    final updated = <String, Map<String, int>>{
      for (final entry in stats.entries)
        entry.key: Map<String, int>.of(entry.value),
    };
    updated.putIfAbsent(key, () => <String, int>{})[statId] = value;
    return CombatState(
      encounterId: encounterId,
      campaignId: campaignId,
      rulesetId: rulesetId,
      rulesetVersion: rulesetVersion,
      revision: revision + 1,
      turnOrder: turnOrder,
      round: round,
      turnIndex: turnIndex,
      actions: actions,
      stats: updated,
      conditions: conditions,
    );
  }
  CombatState applyCondition(CombatCondition condition) {
    final updated = <CombatCondition>[
      for (final item in conditions)
        if (item.key != condition.key) item,
      condition,
    ];
    return _withConditions(updated);
  }

  CombatState removeCondition({
    required String participantKey,
    required String conditionId,
  }) {
    final key = '${participantKey.trim().toLowerCase()}:${conditionId.trim()}';
    final updated = conditions.where((item) => item.key != key).toList();
    if (updated.length == conditions.length) {
      throw StateError('Combat condition not found: $key.');
    }
    return _withConditions(updated);
  }

  CombatState _withConditions(List<CombatCondition> updated) => CombatState(
        encounterId: encounterId,
        campaignId: campaignId,
        rulesetId: rulesetId,
        rulesetVersion: rulesetVersion,
        revision: revision + 1,
        turnOrder: turnOrder,
        round: round,
        turnIndex: turnIndex,
        actions: actions,
        stats: stats,
        conditions: updated,
      );

}

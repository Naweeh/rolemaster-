import '../encounter/encounter.dart';
import '../encounter/encounter_status.dart';
import '../resolution/resolution_engine.dart';
import '../resolution/resolution_request.dart';
import '../resolution/resolution_result.dart';
import '../ruleset/effective_ruleset.dart';
import 'combat_modifier_trace.dart';
import 'combat_participant.dart';
import 'combat_state.dart';
import 'ruleset_combat_stat_catalog.dart';
import 'ruleset_condition_catalog.dart';

final class CombatEngine {
  CombatEngine({
    required CombatParticipantResolver participantResolver,
    required ResolutionEngine resolutionEngine,
  })  : _participantResolver = participantResolver,
        _resolutionEngine = resolutionEngine;

  final CombatParticipantResolver _participantResolver;
  final ResolutionEngine _resolutionEngine;

  Future<CombatState> start({
    required Encounter encounter,
    required EffectiveRuleset ruleset,
    required List<String> turnOrder,
    Map<String, Map<String, int>> initialStats =
        const <String, Map<String, int>>{},
  }) async {
    _validateEncounter(encounter, ruleset);
    final participants = await _participantResolver.resolve(encounter);
    if (participants.isEmpty) {
      throw StateError('Combat requires at least one participant.');
    }
    final byKey = <String, CombatParticipant>{
      for (final participant in participants) participant.key: participant,
    };
    final keys = turnOrder.map((key) => key.trim().toLowerCase()).toList();
    if (keys.length != byKey.length ||
        keys.toSet().length != byKey.length ||
        !keys.every(byKey.containsKey)) {
      throw ArgumentError('Turn order must contain each participant once.');
    }
    final catalog = RulesetCombatStatCatalog(ruleset);
    final stats = <String, Map<String, int>>{};
    for (final participant in participants) {
      final values = <String, int>{};
      for (final definition in catalog.activeDefinitions) {
        if (definition.initial != null) {
          values[definition.id] = definition.initial!;
        }
      }
      stats[participant.key] = values;
    }
    for (final entry in initialStats.entries) {
      final key = entry.key.trim().toLowerCase();
      if (!byKey.containsKey(key)) {
        throw StateError('Combat participant not found: $key.');
      }
      for (final stat in entry.value.entries) {
        final definition = catalog.requireActive(stat.key);
        if (!definition.accepts(stat.value)) {
          throw StateError('Combat stat value is out of range: ${stat.key}.');
        }
        stats[key]![definition.id] = stat.value;
      }
    }
    return CombatState(
      encounterId: encounter.id,
      campaignId: encounter.campaignId,
      rulesetId: ruleset.rulesetId,
      rulesetVersion: ruleset.version,
      turnOrder: <CombatParticipant>[for (final key in keys) byKey[key]!],
      stats: stats,
    );
  }

  CombatState resolveAction({
    required Encounter encounter,
    required EffectiveRuleset ruleset,
    required CombatState state,
    required String actorKey,
    required ResolutionRequest request,
  }) {
    _validateState(encounter, ruleset, state);
    final key = actorKey.trim().toLowerCase();
    if (key != state.currentParticipant.key) {
      throw StateError('Only the current participant can act.');
    }
    final inputs = Map<String, Object?>.of(request.inputs);
    final applied = <CombatModifierTrace>[];
    for (final condition in _activeConditions(ruleset, state, key)) {
      final definition =
          RulesetConditionCatalog(ruleset).requireActive(condition.conditionId);
      final fields = definition.resolutionModifiers.keys.toList()..sort();
      for (final field in fields) {
        final base = inputs[field];
        if (base is! int) {
          throw StateError('Effect modifier requires integer input: $field.');
        }
        final delta = definition.resolutionModifiers[field]!;
        inputs[field] = base + delta;
        applied.add(CombatModifierTrace(
          conditionId: definition.id,
          field: field,
          delta: delta,
        ));
      }
    }
    final resolved = _resolutionEngine.resolve(
      ruleset: ruleset,
      request: ResolutionRequest(
        ruleId: request.ruleId,
        inputs: inputs,
        purpose: request.purpose,
      ),
    );
    if (applied.isNotEmpty && resolved.details.containsKey('combatEffects')) {
      throw StateError('Resolution details already define combatEffects.');
    }
    final result = applied.isEmpty
        ? resolved
        : ResolutionResult(
            id: resolved.id,
            campaignId: resolved.campaignId,
            rulesetId: resolved.rulesetId,
            rulesetVersion: resolved.rulesetVersion,
            ruleId: resolved.ruleId,
            ruleKind: resolved.ruleKind,
            outcome: resolved.outcome,
            details: <String, Object?>{
              ...resolved.details,
              'combatEffects': <Map<String, Object?>>[
                for (final modifier in applied) modifier.toJson(),
              ],
            },
            diceRolls: resolved.diceRolls,
            purpose: resolved.purpose,
            occurredAt: resolved.occurredAt,
          );
    return state.addAction(CombatAction(actorKey: key, result: result));
  }

  CombatState setStat({
    required Encounter encounter,
    required EffectiveRuleset ruleset,
    required CombatState state,
    required String participantKey,
    required String statId,
    required int value,
  }) {
    _validateState(encounter, ruleset, state);
    final definition = RulesetCombatStatCatalog(ruleset).requireActive(statId);
    if (!definition.accepts(value)) {
      throw StateError('Combat stat value is out of range: $statId.');
    }
    return state.setStat(
      participantKey: participantKey,
      statId: definition.id,
      value: value,
    );
  }

  CombatState applyCondition({
    required Encounter encounter,
    required EffectiveRuleset ruleset,
    required CombatState state,
    required String participantKey,
    required String conditionId,
    int? durationRounds,
    String? sourceKey,
  }) {
    _validateState(encounter, ruleset, state);
    final definition =
        RulesetConditionCatalog(ruleset).requireActive(conditionId);
    return state.applyCondition(CombatCondition(
      participantKey: participantKey,
      conditionId: definition.id,
      remainingRounds: durationRounds ?? definition.durationRounds,
      sourceKey: sourceKey,
    ));
  }

  CombatState removeCondition({
    required Encounter encounter,
    required EffectiveRuleset ruleset,
    required CombatState state,
    required String participantKey,
    required String conditionId,
  }) {
    _validateState(encounter, ruleset, state);
    return state.removeCondition(
      participantKey: participantKey,
      conditionId: conditionId,
    );
  }

  CombatStatEvaluation effectiveStat({
    required Encounter encounter,
    required EffectiveRuleset ruleset,
    required CombatState state,
    required String participantKey,
    required String statId,
  }) {
    _validateState(encounter, ruleset, state);
    final key = participantKey.trim().toLowerCase();
    final definition = RulesetCombatStatCatalog(ruleset).requireActive(statId);
    if (!state.turnOrder.any((item) => item.key == key)) {
      throw StateError('Combat participant not found: $key.');
    }
    final base = state.stats[key]?[definition.id];
    if (base == null) {
      throw StateError('Combat stat has no base value: ${definition.id}.');
    }
    var total = base;
    final applied = <CombatModifierTrace>[];
    for (final condition in _activeConditions(ruleset, state, key)) {
      final effect =
          RulesetConditionCatalog(ruleset).requireActive(condition.conditionId);
      final delta = effect.statModifiers[definition.id];
      if (delta != null) {
        total += delta;
        applied.add(CombatModifierTrace(
          conditionId: effect.id,
          field: definition.id,
          delta: delta,
        ));
      }
    }
    return CombatStatEvaluation(
      baseValue: base,
      effectiveValue: total,
      modifiers: applied,
    );
  }

  List<CombatCondition> _activeConditions(
    EffectiveRuleset ruleset,
    CombatState state,
    String participantKey,
  ) {
    final conditions = state.conditions
        .where((item) => item.participantKey == participantKey)
        .toList()
      ..sort((left, right) => left.conditionId.compareTo(right.conditionId));
    final catalog = RulesetConditionCatalog(ruleset);
    for (final condition in conditions) {
      catalog.requireActive(condition.conditionId);
    }
    return conditions;
  }

  void _validateState(
    Encounter encounter,
    EffectiveRuleset ruleset,
    CombatState state,
  ) {
    _validateEncounter(encounter, ruleset);
    if (state.encounterId != encounter.id ||
        state.campaignId != encounter.campaignId ||
        state.rulesetId != ruleset.rulesetId ||
        state.rulesetVersion != ruleset.version) {
      throw StateError('Combat state belongs to another encounter.');
    }
    final encounterKeys =
        encounter.participants.map((item) => item.key).toSet();
    if (encounterKeys.length != state.turnOrder.length ||
        !state.turnOrder.every((item) => encounterKeys.contains(item.key))) {
      throw StateError('Encounter participants changed during combat.');
    }
  }

  void _validateEncounter(Encounter encounter, EffectiveRuleset ruleset) {
    if (encounter.status != EncounterStatus.active) {
      throw StateError('Combat requires an active encounter.');
    }
    if (ruleset.campaignId != encounter.campaignId) {
      throw StateError('Combat ruleset belongs to another campaign.');
    }
  }
}

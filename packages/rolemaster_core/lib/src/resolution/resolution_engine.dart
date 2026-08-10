import '../dice/dice_engine.dart';
import '../ruleset/effective_ruleset.dart';
import 'resolution_exceptions.dart';
import 'resolution_request.dart';
import 'resolution_result.dart';
import 'resolution_rule_interpreter.dart';
import 'ruleset_resolution_catalog.dart';

typedef ResolutionResultIdGenerator = String Function();
typedef ResolutionClock = DateTime Function();

final class ResolutionEngine {
  ResolutionEngine({
    required DiceEngine diceEngine,
    required Iterable<ResolutionRuleInterpreter> interpreters,
    required ResolutionResultIdGenerator idGenerator,
    required ResolutionClock clock,
  })  : _diceEngine = diceEngine,
        _interpreters = _indexInterpreters(interpreters),
        _idGenerator = idGenerator,
        _clock = clock;

  final DiceEngine _diceEngine;
  final Map<String, ResolutionRuleInterpreter> _interpreters;
  final ResolutionResultIdGenerator _idGenerator;
  final ResolutionClock _clock;

  ResolutionResult resolve({
    required EffectiveRuleset ruleset,
    required ResolutionRequest request,
  }) {
    final definition = RulesetResolutionCatalog(ruleset).find(request.ruleId);
    if (definition == null) {
      throw ResolutionRuleNotFoundException(request.ruleId);
    }

    final moduleId = definition.moduleId;
    if (moduleId != null && !ruleset.isModuleActive(moduleId)) {
      throw ResolutionModuleInactiveException(definition.id, moduleId);
    }

    final interpreter = _interpreters[definition.kind];
    if (interpreter == null) {
      throw ResolutionInterpreterNotFoundException(definition.kind);
    }

    final evaluation = interpreter.evaluate(
      ruleset: ruleset,
      definition: definition,
      request: request,
      diceEngine: _diceEngine,
    );

    for (final roll in evaluation.diceRolls) {
      if (roll.campaignId != ruleset.campaignId ||
          roll.rulesetId != ruleset.rulesetId ||
          roll.rulesetVersion != ruleset.version) {
        throw StateError(
          'Resolution interpreter returned a dice roll from another '
          'campaign or ruleset.',
        );
      }
    }

    return ResolutionResult(
      id: _idGenerator(),
      campaignId: ruleset.campaignId,
      rulesetId: ruleset.rulesetId,
      rulesetVersion: ruleset.version,
      ruleId: definition.id,
      ruleKind: definition.kind,
      outcome: evaluation.outcome,
      details: evaluation.details,
      diceRolls: evaluation.diceRolls,
      purpose: request.purpose,
      occurredAt: _clock(),
    );
  }
}

Map<String, ResolutionRuleInterpreter> _indexInterpreters(
  Iterable<ResolutionRuleInterpreter> interpreters,
) {
  final result = <String, ResolutionRuleInterpreter>{};
  for (final interpreter in interpreters) {
    final kind = interpreter.kind.trim();
    if (kind.isEmpty) {
      throw ArgumentError('Resolution interpreter kind cannot be empty.');
    }
    if (result.containsKey(kind)) {
      throw DuplicateResolutionInterpreterException(kind);
    }
    result[kind] = interpreter;
  }
  return Map<String, ResolutionRuleInterpreter>.unmodifiable(result);
}

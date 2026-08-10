import '../dice/dice_engine.dart';
import '../ruleset/effective_ruleset.dart';
import 'resolution_evaluation.dart';
import 'resolution_request.dart';
import 'resolution_rule_definition.dart';

abstract interface class ResolutionRuleInterpreter {
  String get kind;

  ResolutionEvaluation evaluate({
    required EffectiveRuleset ruleset,
    required ResolutionRuleDefinition definition,
    required ResolutionRequest request,
    required DiceEngine diceEngine,
  });
}

import '../dice/dice_engine.dart';
import '../dice/dice_formula.dart';
import '../dice/dice_roll_result.dart';
import '../ruleset/effective_ruleset.dart';
import 'resolution_evaluation.dart';
import 'resolution_request.dart';
import 'resolution_rule_definition.dart';
import 'resolution_rule_interpreter.dart';

final class DiceThresholdResolutionInterpreter
    implements ResolutionRuleInterpreter {
  static const String interpreterKind = 'dice-threshold';

  @override
  String get kind => interpreterKind;

  @override
  ResolutionEvaluation evaluate({
    required EffectiveRuleset ruleset,
    required ResolutionRuleDefinition definition,
    required ResolutionRequest request,
    required DiceEngine diceEngine,
  }) {
    final config = definition.config;
    final dice = _requiredMap(config['dice'], 'dice');
    final count = _requiredInt(dice['count'], 'dice.count');
    final sides = _requiredInt(dice['sides'], 'dice.sides');
    final baseModifier = _optionalInt(dice['modifier'], 'dice.modifier') ?? 0;

    final modifierInput = _optionalString(config['modifierInput']);
    final dynamicModifier = modifierInput == null
        ? 0
        : _requiredInt(
            request.inputs[modifierInput],
            'request.inputs.$modifierInput',
          );

    final targetInput = _optionalString(config['targetInput']);
    final target = targetInput == null
        ? _requiredInt(config['target'], 'target')
        : _requiredInt(
            request.inputs[targetInput],
            'request.inputs.$targetInput',
          );

    final successOutcome =
        _optionalString(config['successOutcome']) ?? 'success';
    final failureOutcome =
        _optionalString(config['failureOutcome']) ?? 'failure';

    final roll = diceEngine.roll(
      ruleset: ruleset,
      formula: DiceFormula(
        count: count,
        sides: sides,
        modifier: baseModifier + dynamicModifier,
      ),
      purpose: request.purpose,
    );

    return ResolutionEvaluation(
      outcome: roll.total >= target ? successOutcome : failureOutcome,
      details: <String, Object?>{
        'target': target,
        'diceTotal': roll.diceTotal,
        'modifier': roll.formula.modifier,
        'total': roll.total,
      },
      diceRolls: <DiceRollResult>[roll],
    );
  }
}

Map<String, Object?> _requiredMap(Object? value, String field) {
  if (value is! Map) {
    throw StateError('$field must be an object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw StateError('$field keys must be strings.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

int _requiredInt(Object? value, String field) {
  if (value is! int) {
    throw StateError('$field must be an integer.');
  }
  return value;
}

int? _optionalInt(Object? value, String field) {
  if (value == null) {
    return null;
  }
  return _requiredInt(value, field);
}

String? _optionalString(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw StateError('Expected a string value.');
  }
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

import '../dice/dice_engine.dart';
import '../ruleset/effective_ruleset.dart';
import '../tables/ruleset_table_catalog.dart';
import 'resolution_evaluation.dart';
import 'resolution_request.dart';
import 'resolution_rule_definition.dart';
import 'resolution_rule_interpreter.dart';

final class TableLookupResolutionInterpreter
    implements ResolutionRuleInterpreter {
  static const String interpreterKind = 'table-lookup';

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
    final tableId = _requiredString(config['tableId'], 'tableId');
    final hasFixedInput = config.containsKey('input');
    final hasInputKey = config.containsKey('inputKey');
    if (hasFixedInput == hasInputKey) {
      throw StateError('Configure exactly one of input or inputKey.');
    }
    final input = hasFixedInput
        ? _requiredInt(config['input'], 'input')
        : _requiredInt(
            request.inputs[_requiredString(config['inputKey'], 'inputKey')],
            'request input',
          );

    final entry = RulesetTableCatalog(ruleset).lookup(
      tableId: tableId,
      value: input,
    );
    final details = <String, Object?>{
      'tableId': tableId,
      'input': input,
      'min': entry?.min,
      'max': entry?.max,
      'result': entry?.result,
    };
    if (entry == null) {
      return ResolutionEvaluation(
        outcome: _requiredString(config['noMatchOutcome'], 'noMatchOutcome'),
        details: details,
      );
    }

    final outcome = config['matchOutcome'] ??
        entry.result['outcome'] ??
        'matched';
    return ResolutionEvaluation(
      outcome: _requiredString(outcome, 'match outcome'),
      details: details,
    );
  }
}

String _requiredString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw StateError('$field must be a non-empty string.');
  }
  return value.trim();
}

int _requiredInt(Object? value, String field) {
  if (value is! int) {
    throw StateError('$field must be an integer.');
  }
  return value;
}

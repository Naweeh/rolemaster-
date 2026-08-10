import '../dice/dice_roll_result.dart';

final class ResolutionEvaluation {
  ResolutionEvaluation({
    required String outcome,
    Map<String, Object?> details = const <String, Object?>{},
    Iterable<DiceRollResult> diceRolls = const <DiceRollResult>[],
  })  : outcome = _required(outcome, 'outcome'),
        details = Map<String, Object?>.unmodifiable(details),
        diceRolls = List<DiceRollResult>.unmodifiable(diceRolls);

  final String outcome;
  final Map<String, Object?> details;
  final List<DiceRollResult> diceRolls;
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, '$field cannot be empty.');
  }
  return normalized;
}

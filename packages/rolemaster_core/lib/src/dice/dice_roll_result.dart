import 'dice_formula.dart';

final class DiceRollResult {
  DiceRollResult({
    required String id,
    required String campaignId,
    required String rulesetId,
    required String rulesetVersion,
    required this.formula,
    required Iterable<int> rolls,
    String? purpose,
    required DateTime occurredAt,
  })  : id = _required(id, 'id'),
        campaignId = _required(campaignId, 'campaignId'),
        rulesetId = _required(rulesetId, 'rulesetId'),
        rulesetVersion = _required(rulesetVersion, 'rulesetVersion'),
        rolls = List<int>.unmodifiable(rolls),
        purpose = _optional(purpose),
        occurredAt = occurredAt.toUtc() {
    if (this.rolls.length != formula.count) {
      throw ArgumentError(
        'Dice roll result must contain exactly ${formula.count} rolls.',
      );
    }
    for (final roll in this.rolls) {
      if (roll < 1 || roll > formula.sides) {
        throw ArgumentError.value(
          roll,
          'rolls',
          'Each die result must be between 1 and ${formula.sides}.',
        );
      }
    }
  }

  final String id;
  final String campaignId;
  final String rulesetId;
  final String rulesetVersion;
  final DiceFormula formula;
  final List<int> rolls;
  final String? purpose;
  final DateTime occurredAt;

  int get diceTotal => rolls.fold<int>(0, (total, value) => total + value);

  int get total => diceTotal + formula.modifier;
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, '$field cannot be empty.');
  }
  return normalized;
}

String? _optional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

import '../dice/dice_roll_result.dart';

final class ResolutionResult {
  ResolutionResult({
    required String id,
    required String campaignId,
    required String rulesetId,
    required String rulesetVersion,
    required String ruleId,
    required String ruleKind,
    required String outcome,
    Map<String, Object?> details = const <String, Object?>{},
    Iterable<DiceRollResult> diceRolls = const <DiceRollResult>[],
    String? purpose,
    required DateTime occurredAt,
  })  : id = _required(id, 'id'),
        campaignId = _required(campaignId, 'campaignId'),
        rulesetId = _required(rulesetId, 'rulesetId'),
        rulesetVersion = _required(rulesetVersion, 'rulesetVersion'),
        ruleId = _required(ruleId, 'ruleId'),
        ruleKind = _required(ruleKind, 'ruleKind'),
        outcome = _required(outcome, 'outcome'),
        details = Map<String, Object?>.unmodifiable(details),
        diceRolls = List<DiceRollResult>.unmodifiable(diceRolls),
        purpose = _optional(purpose),
        occurredAt = occurredAt.toUtc();

  final String id;
  final String campaignId;
  final String rulesetId;
  final String rulesetVersion;
  final String ruleId;
  final String ruleKind;
  final String outcome;
  final Map<String, Object?> details;
  final List<DiceRollResult> diceRolls;
  final String? purpose;
  final DateTime occurredAt;
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

final class CombatModifierTrace {
  CombatModifierTrace({
    required String conditionId,
    required String field,
    required this.delta,
  })  : conditionId = conditionId.trim(),
        field = field.trim();

  final String conditionId;
  final String field;
  final int delta;

  Map<String, Object?> toJson() => <String, Object?>{
        'conditionId': conditionId,
        'field': field,
        'delta': delta,
      };
}

final class CombatStatEvaluation {
  CombatStatEvaluation({
    required this.baseValue,
    required this.effectiveValue,
    required Iterable<CombatModifierTrace> modifiers,
  }) : modifiers = List<CombatModifierTrace>.unmodifiable(modifiers);

  final int baseValue;
  final int effectiveValue;
  final List<CombatModifierTrace> modifiers;
}

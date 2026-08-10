final class CharacterSkillState {
  CharacterSkillState({
    required String characterId,
    required String skillId,
    required int ranks,
    Map<String, int> modifiers = const <String, int>{},
    String? notes,
    required DateTime updatedAt,
  })  : characterId = _required(characterId, 'characterId'),
        skillId = _required(skillId, 'skillId'),
        ranks = ranks,
        modifiers = Map<String, int>.unmodifiable(_normalizeModifiers(modifiers)),
        notes = _optional(notes),
        updatedAt = updatedAt.toUtc() {
    if (ranks < 0) {
      throw ArgumentError.value(ranks, 'ranks', 'Skill ranks cannot be negative.');
    }
  }

  final String characterId;
  final String skillId;
  final int ranks;
  final Map<String, int> modifiers;
  final String? notes;
  final DateTime updatedAt;

  int get modifierTotal => modifiers.values.fold(0, (total, value) => total + value);

  CharacterSkillState update({
    int? ranks,
    Map<String, int>? modifiers,
    String? notes,
    bool clearNotes = false,
    required DateTime at,
  }) {
    final normalizedAt = at.toUtc();
    if (normalizedAt.isBefore(updatedAt)) {
      throw ArgumentError.value(
        at,
        'at',
        'Character skill changes cannot move backwards in time.',
      );
    }

    return CharacterSkillState(
      characterId: characterId,
      skillId: skillId,
      ranks: ranks ?? this.ranks,
      modifiers: modifiers ?? this.modifiers,
      notes: clearNotes ? null : notes ?? this.notes,
      updatedAt: normalizedAt,
    );
  }
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

Map<String, int> _normalizeModifiers(Map<String, int> source) {
  final result = <String, int>{};
  for (final entry in source.entries) {
    final key = entry.key.trim();
    if (key.isEmpty) {
      throw ArgumentError.value(entry.key, 'modifiers', 'Modifier keys cannot be empty.');
    }
    result[key] = entry.value;
  }
  return result;
}

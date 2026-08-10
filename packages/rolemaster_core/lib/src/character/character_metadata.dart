final class CharacterMetadata {
  CharacterMetadata({
    String? playerName,
    String? description,
    String? notes,
    Iterable<String> tags = const <String>[],
  })  : playerName = _normalizeOptionalText(playerName),
        description = _normalizeOptionalText(description),
        notes = _normalizeOptionalText(notes),
        tags = List<String>.unmodifiable(_normalizeTags(tags));

  final String? playerName;
  final String? description;
  final String? notes;
  final List<String> tags;

  static String? _normalizeOptionalText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static List<String> _normalizeTags(Iterable<String> values) {
    final seen = <String>{};
    final normalized = <String>[];

    for (final value in values) {
      final tag = value.trim();
      if (tag.isEmpty) {
        continue;
      }
      final key = tag.toLowerCase();
      if (seen.add(key)) {
        normalized.add(tag);
      }
    }

    return normalized;
  }
}

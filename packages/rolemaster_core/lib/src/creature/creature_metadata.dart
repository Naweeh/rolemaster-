final class CreatureMetadata {
  CreatureMetadata({
    required String species,
    String? category,
    String? description,
    String? notes,
    Iterable<String> tags = const <String>[],
  })  : species = _normalizeRequired(species, 'species'),
        category = _normalizeOptional(category),
        description = _normalizeOptional(description),
        notes = _normalizeOptional(notes),
        tags = List<String>.unmodifiable(_normalizeTags(tags));

  final String species;
  final String? category;
  final String? description;
  final String? notes;
  final List<String> tags;

  static String _normalizeRequired(String value, String fieldName) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, fieldName, '$fieldName cannot be empty.');
    }
    return normalized;
  }

  static String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static List<String> _normalizeTags(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final tag = value.trim();
      if (tag.isEmpty) {
        continue;
      }
      if (seen.add(tag.toLowerCase())) {
        result.add(tag);
      }
    }
    return result;
  }
}

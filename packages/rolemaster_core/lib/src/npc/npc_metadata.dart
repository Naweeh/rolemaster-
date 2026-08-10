final class NpcMetadata {
  NpcMetadata({
    required String nativeLanguage,
    Iterable<String> knownLanguages = const <String>[],
    String? role,
    String? description,
    String? notes,
    Iterable<String> tags = const <String>[],
  })  : nativeLanguage = _normalizeRequiredLanguage(nativeLanguage),
        knownLanguages = List<String>.unmodifiable(
          _normalizeValues(
            knownLanguages,
            excludedValue: nativeLanguage,
          ),
        ),
        role = _normalizeOptionalText(role),
        description = _normalizeOptionalText(description),
        notes = _normalizeOptionalText(notes),
        tags = List<String>.unmodifiable(_normalizeValues(tags));

  final String nativeLanguage;
  final List<String> knownLanguages;
  final String? role;
  final String? description;
  final String? notes;
  final List<String> tags;

  List<String> get spokenLanguages => List<String>.unmodifiable(
        <String>[nativeLanguage, ...knownLanguages],
      );

  static String _normalizeRequiredLanguage(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        'nativeLanguage',
        'NPC native language cannot be empty.',
      );
    }
    return normalized;
  }

  static String? _normalizeOptionalText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static List<String> _normalizeValues(
    Iterable<String> values, {
    String? excludedValue,
  }) {
    final excludedKey = excludedValue?.trim().toLowerCase();
    final seen = <String>{};
    final normalized = <String>[];

    for (final value in values) {
      final item = value.trim();
      if (item.isEmpty) {
        continue;
      }
      final key = item.toLowerCase();
      if (key == excludedKey) {
        continue;
      }
      if (seen.add(key)) {
        normalized.add(item);
      }
    }
    return normalized;
  }
}

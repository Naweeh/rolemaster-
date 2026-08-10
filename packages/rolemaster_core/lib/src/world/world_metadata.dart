final class WorldMetadata {
  WorldMetadata({
    String? description,
    Iterable<String> tags = const <String>[],
  })  : description = _normalizeOptionalText(description),
        tags = List<String>.unmodifiable(_normalizeTags(tags));

  final String? description;
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

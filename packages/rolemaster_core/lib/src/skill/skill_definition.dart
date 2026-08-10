final class SkillDefinition {
  SkillDefinition({
    required String id,
    required String name,
    String? moduleId,
    String? category,
    String? description,
    Iterable<String> tags = const <String>[],
  })  : id = _required(id, 'id'),
        name = _required(name, 'name'),
        moduleId = _optional(moduleId),
        category = _optional(category),
        description = _optional(description),
        tags = List<String>.unmodifiable(_unique(tags));

  final String id;
  final String name;
  final String? moduleId;
  final String? category;
  final String? description;
  final List<String> tags;
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

List<String> _unique(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isNotEmpty && seen.add(normalized)) {
      result.add(normalized);
    }
  }
  return result;
}

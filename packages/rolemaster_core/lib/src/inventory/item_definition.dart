final class ItemDefinition {
  ItemDefinition({
    required String id,
    required String name,
    String? moduleId,
    String? category,
    String? description,
    Iterable<String> tags = const <String>[],
    Map<String, Object?> properties = const <String, Object?>{},
  })  : id = _required(id, 'id'),
        name = _required(name, 'name'),
        moduleId = _optional(moduleId),
        category = _optional(category),
        description = _optional(description),
        tags = List<String>.unmodifiable(_unique(tags)),
        properties = _freezeMap(properties);

  final String id;
  final String name;
  final String? moduleId;
  final String? category;
  final String? description;
  final List<String> tags;
  final Map<String, Object?> properties;
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

Map<String, Object?> _freezeMap(Map<String, Object?> source) {
  return Map<String, Object?>.unmodifiable(
    source.map((key, value) => MapEntry(key, _freeze(value))),
  );
}

Object? _freeze(Object? value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_freeze));
  }
  if (value is Map) {
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw ArgumentError('Item property object keys must be strings.');
      }
      result[entry.key as String] = _freeze(entry.value);
    }
    return Map<String, Object?>.unmodifiable(result);
  }
  throw ArgumentError.value(
    value,
    'properties',
    'Item properties must contain only JSON-compatible values.',
  );
}

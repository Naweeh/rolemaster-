final class ResolutionRuleDefinition {
  ResolutionRuleDefinition({
    required String id,
    required String kind,
    String? moduleId,
    Map<String, Object?> config = const <String, Object?>{},
  })  : id = _required(id, 'id'),
        kind = _required(kind, 'kind'),
        moduleId = _optional(moduleId),
        config = Map<String, Object?>.unmodifiable(config);

  final String id;
  final String kind;
  final String? moduleId;
  final Map<String, Object?> config;
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

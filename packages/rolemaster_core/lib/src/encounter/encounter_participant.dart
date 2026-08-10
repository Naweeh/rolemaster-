final class EncounterParticipant {
  EncounterParticipant({
    required String entityType,
    required String entityId,
    String? label,
  })  : entityType = _required(entityType, 'entityType'),
        entityId = _required(entityId, 'entityId'),
        label = _optional(label);

  final String entityType;
  final String entityId;
  final String? label;

  String get key => '${entityType.toLowerCase()}:$entityId';
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

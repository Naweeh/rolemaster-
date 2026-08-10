final class SceneEntityPosition {
  SceneEntityPosition({
    required String sceneMapId,
    required String entityType,
    required String entityId,
    required this.x,
    required this.y,
    String? layerId,
    required DateTime updatedAt,
  })  : sceneMapId = _required(sceneMapId, 'sceneMapId'),
        entityType = _required(entityType, 'entityType'),
        entityId = _required(entityId, 'entityId'),
        layerId = _optional(layerId),
        updatedAt = updatedAt.toUtc() {
    if (!x.isFinite || !y.isFinite) {
      throw ArgumentError('Entity map coordinates must be finite.');
    }
  }

  final String sceneMapId;
  final String entityType;
  final String entityId;
  final double x;
  final double y;
  final String? layerId;
  final DateTime updatedAt;
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

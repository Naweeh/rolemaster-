enum SceneLayerVisibility { gmOnly, shared }

final class SceneLayer {
  SceneLayer({
    required String id,
    required String sceneMapId,
    required String name,
    required this.orderIndex,
    this.visibility = SceneLayerVisibility.gmOnly,
  })  : id = _required(id, 'id'),
        sceneMapId = _required(sceneMapId, 'sceneMapId'),
        name = _required(name, 'name') {
    if (orderIndex < 0) {
      throw ArgumentError.value(
        orderIndex,
        'orderIndex',
        'Layer orderIndex cannot be negative.',
      );
    }
  }

  final String id;
  final String sceneMapId;
  final String name;
  final int orderIndex;
  final SceneLayerVisibility visibility;
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, '$field cannot be empty.');
  }
  return normalized;
}

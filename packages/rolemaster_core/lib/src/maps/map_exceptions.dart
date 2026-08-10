final class SceneMapNotFoundException implements Exception {
  SceneMapNotFoundException(this.sceneMapId);

  final String sceneMapId;

  @override
  String toString() => 'Scene map not found: $sceneMapId';
}

final class SceneLayerNotFoundException implements Exception {
  SceneLayerNotFoundException(this.layerId);

  final String layerId;

  @override
  String toString() => 'Scene layer not found: $layerId';
}

final class SceneLayerOrderConflictException implements Exception {
  SceneLayerOrderConflictException(this.sceneMapId, this.orderIndex);

  final String sceneMapId;
  final int orderIndex;

  @override
  String toString() =>
      'Scene map $sceneMapId already has a layer at order $orderIndex.';
}

final class ScenePositionOutsideMapException implements Exception {
  ScenePositionOutsideMapException(this.sceneMapId, this.x, this.y);

  final String sceneMapId;
  final double x;
  final double y;

  @override
  String toString() =>
      'Position ($x, $y) is outside scene map $sceneMapId coordinate space.';
}

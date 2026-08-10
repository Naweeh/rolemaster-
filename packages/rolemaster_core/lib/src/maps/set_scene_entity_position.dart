import 'map_exceptions.dart';
import 'scene_entity_position.dart';
import 'scene_map_repository.dart';

typedef ScenePositionClock = DateTime Function();

final class SetSceneEntityPosition {
  SetSceneEntityPosition({
    required SceneMapRepository repository,
    required ScenePositionClock clock,
  })  : _repository = repository,
        _clock = clock;

  final SceneMapRepository _repository;
  final ScenePositionClock _clock;

  Future<SceneEntityPosition> call({
    required String sceneMapId,
    required String entityType,
    required String entityId,
    required double x,
    required double y,
    String? layerId,
  }) async {
    final map = await _repository.getMapById(sceneMapId);
    if (map == null) {
      throw SceneMapNotFoundException(sceneMapId);
    }
    if (!map.coordinateSpace.contains(x, y)) {
      throw ScenePositionOutsideMapException(map.id, x, y);
    }

    final normalizedLayerId = _optional(layerId);
    if (normalizedLayerId != null) {
      final layer = await _repository.getLayerById(normalizedLayerId);
      if (layer == null) {
        throw SceneLayerNotFoundException(normalizedLayerId);
      }
      if (layer.sceneMapId != map.id) {
        throw StateError(
            'Position layer must belong to the selected scene map.');
      }
    }

    final position = SceneEntityPosition(
      sceneMapId: map.id,
      entityType: entityType,
      entityId: entityId,
      x: x,
      y: y,
      layerId: normalizedLayerId,
      updatedAt: _clock(),
    );
    await _repository.saveEntityPosition(position);
    return position;
  }
}

String? _optional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

import 'map_exceptions.dart';
import 'scene_layer.dart';
import 'scene_map_repository.dart';

typedef SceneLayerIdGenerator = String Function();

final class AddSceneLayer {
  AddSceneLayer({
    required SceneMapRepository repository,
    required SceneLayerIdGenerator idGenerator,
  })  : _repository = repository,
        _idGenerator = idGenerator;

  final SceneMapRepository _repository;
  final SceneLayerIdGenerator _idGenerator;

  Future<SceneLayer> call({
    required String sceneMapId,
    required String name,
    required int orderIndex,
    SceneLayerVisibility visibility = SceneLayerVisibility.gmOnly,
  }) async {
    final map = await _repository.getMapById(sceneMapId);
    if (map == null) {
      throw SceneMapNotFoundException(sceneMapId);
    }

    final layers = await _repository.getLayersForMap(map.id);
    if (layers.any((layer) => layer.orderIndex == orderIndex)) {
      throw SceneLayerOrderConflictException(map.id, orderIndex);
    }

    final layer = SceneLayer(
      id: _idGenerator(),
      sceneMapId: map.id,
      name: name,
      orderIndex: orderIndex,
      visibility: visibility,
    );
    await _repository.saveLayer(layer);
    return layer;
  }
}

import 'scene_entity_position.dart';
import 'scene_layer.dart';
import 'scene_map.dart';

abstract interface class SceneMapRepository {
  Future<SceneMap?> getMapById(String id);

  Future<List<SceneMap>> getMapsForCampaign(String campaignId);

  Future<void> saveMap(SceneMap map);

  Future<SceneLayer?> getLayerById(String id);

  Future<List<SceneLayer>> getLayersForMap(String sceneMapId);

  Future<void> saveLayer(SceneLayer layer);

  Future<SceneEntityPosition?> getEntityPosition({
    required String sceneMapId,
    required String entityType,
    required String entityId,
  });

  Future<List<SceneEntityPosition>> getEntityPositionsForMap(String sceneMapId);

  Future<void> saveEntityPosition(SceneEntityPosition position);
}

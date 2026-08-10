import '../campaign/campaign_not_found_exception.dart';
import '../campaign/campaign_repository.dart';
import '../world/world_exceptions.dart';
import '../world/world_repository.dart';
import 'scene_coordinate_space.dart';
import 'scene_map.dart';
import 'scene_map_repository.dart';

typedef SceneMapIdGenerator = String Function();
typedef SceneClock = DateTime Function();

final class CreateSceneMap {
  CreateSceneMap({
    required CampaignRepository campaignRepository,
    required WorldRepository worldRepository,
    required SceneMapRepository sceneMapRepository,
    required SceneMapIdGenerator idGenerator,
    required SceneClock clock,
  })  : _campaignRepository = campaignRepository,
        _worldRepository = worldRepository,
        _sceneMapRepository = sceneMapRepository,
        _idGenerator = idGenerator,
        _clock = clock;

  final CampaignRepository _campaignRepository;
  final WorldRepository _worldRepository;
  final SceneMapRepository _sceneMapRepository;
  final SceneMapIdGenerator _idGenerator;
  final SceneClock _clock;

  Future<SceneMap> call({
    required String campaignId,
    required String name,
    String? worldId,
    String? locationId,
    required SceneCoordinateSpace coordinateSpace,
    String? notes,
  }) async {
    final normalizedCampaignId = campaignId.trim();
    final campaign = await _campaignRepository.getById(normalizedCampaignId);
    if (campaign == null) {
      throw CampaignNotFoundException(normalizedCampaignId);
    }
    if (campaign.isArchived) {
      throw StateError('Cannot create maps in an archived campaign.');
    }

    final normalizedWorldId = _optional(worldId);
    final normalizedLocationId = _optional(locationId);
    if (normalizedLocationId != null && normalizedWorldId == null) {
      throw ArgumentError('A map location requires worldId.');
    }
    if (normalizedWorldId != null) {
      final world = await _worldRepository.getWorldById(normalizedWorldId);
      if (world == null) {
        throw WorldNotFoundException(normalizedWorldId);
      }
      if (world.campaignId != normalizedCampaignId) {
        throw StateError('Map world must belong to the same campaign.');
      }
    }
    if (normalizedLocationId != null) {
      final location =
          await _worldRepository.getLocationById(normalizedLocationId);
      if (location == null) {
        throw LocationNotFoundException(normalizedLocationId);
      }
      if (location.worldId != normalizedWorldId) {
        throw StateError('Map location must belong to the selected world.');
      }
    }

    final now = _clock().toUtc();
    final map = SceneMap(
      id: _idGenerator(),
      campaignId: normalizedCampaignId,
      name: name,
      worldId: normalizedWorldId,
      locationId: normalizedLocationId,
      coordinateSpace: coordinateSpace,
      notes: notes,
      createdAt: now,
    );
    await _sceneMapRepository.saveMap(map);
    return map;
  }
}

String? _optional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

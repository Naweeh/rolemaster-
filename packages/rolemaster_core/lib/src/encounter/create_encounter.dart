import '../campaign/campaign_not_found_exception.dart';
import '../campaign/campaign_repository.dart';
import '../maps/scene_map_repository.dart';
import '../world/world_repository.dart';
import 'encounter.dart';
import 'encounter_exceptions.dart';
import 'encounter_repository.dart';

final class CreateEncounter {
  CreateEncounter({
    required EncounterRepository repository,
    required CampaignRepository campaignRepository,
    required WorldRepository worldRepository,
    required SceneMapRepository sceneMapRepository,
    required String Function() idGenerator,
    required DateTime Function() clock,
  })  : _repository = repository,
        _campaignRepository = campaignRepository,
        _worldRepository = worldRepository,
        _sceneMapRepository = sceneMapRepository,
        _idGenerator = idGenerator,
        _clock = clock;

  final EncounterRepository _repository;
  final CampaignRepository _campaignRepository;
  final WorldRepository _worldRepository;
  final SceneMapRepository _sceneMapRepository;
  final String Function() _idGenerator;
  final DateTime Function() _clock;

  Future<Encounter> call({
    required String campaignId,
    required String name,
    String? worldId,
    String? locationId,
    String? sceneMapId,
    String? notes,
  }) async {
    final normalizedCampaignId = campaignId.trim();
    final campaign = await _campaignRepository.getById(normalizedCampaignId);
    if (campaign == null) {
      throw CampaignNotFoundException(normalizedCampaignId);
    }
    if (campaign.isArchived) {
      throw StateError('Cannot create encounters in an archived campaign.');
    }

    var resolvedWorldId = _optional(worldId);
    var resolvedLocationId = _optional(locationId);
    final normalizedSceneMapId = _optional(sceneMapId);

    if (normalizedSceneMapId != null) {
      final map = await _sceneMapRepository.getMapById(normalizedSceneMapId);
      if (map == null) {
        throw EncounterContextException('Scene map not found: $normalizedSceneMapId.');
      }
      if (map.campaignId != normalizedCampaignId) {
        throw EncounterContextException(
          'Scene map $normalizedSceneMapId belongs to another campaign.',
        );
      }
      if (resolvedWorldId != null &&
          map.worldId != null &&
          map.worldId != resolvedWorldId) {
        throw EncounterContextException(
          'Scene map world does not match encounter world.',
        );
      }
      if (resolvedLocationId != null &&
          map.locationId != null &&
          map.locationId != resolvedLocationId) {
        throw EncounterContextException(
          'Scene map location does not match encounter location.',
        );
      }
      resolvedWorldId ??= map.worldId;
      resolvedLocationId ??= map.locationId;
    }

    if (resolvedLocationId != null && resolvedWorldId == null) {
      throw EncounterContextException('A location requires a world.');
    }

    if (resolvedWorldId != null) {
      final world = await _worldRepository.getWorldById(resolvedWorldId);
      if (world == null) {
        throw EncounterContextException('World not found: $resolvedWorldId.');
      }
      if (world.campaignId != normalizedCampaignId) {
        throw EncounterContextException(
          'World $resolvedWorldId belongs to another campaign.',
        );
      }
    }

    if (resolvedLocationId != null) {
      final location = await _worldRepository.getLocationById(resolvedLocationId);
      if (location == null) {
        throw EncounterContextException('Location not found: $resolvedLocationId.');
      }
      if (location.worldId != resolvedWorldId) {
        throw EncounterContextException(
          'Location $resolvedLocationId does not belong to world $resolvedWorldId.',
        );
      }
    }

    final now = _clock().toUtc();
    final encounter = Encounter(
      id: _idGenerator(),
      campaignId: normalizedCampaignId,
      name: name,
      worldId: resolvedWorldId,
      locationId: resolvedLocationId,
      sceneMapId: normalizedSceneMapId,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.save(encounter);
    return encounter;
  }
}

String? _optional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

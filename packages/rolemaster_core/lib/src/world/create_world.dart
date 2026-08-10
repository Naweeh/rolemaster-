import '../campaign/campaign_not_found_exception.dart';
import '../campaign/campaign_repository.dart';
import 'world.dart';
import 'world_metadata.dart';
import 'world_repository.dart';
import 'world_support.dart';

final class CreateWorld {
  CreateWorld({
    required CampaignRepository campaignRepository,
    required WorldRepository worldRepository,
    required WorldEntityIdGenerator idGenerator,
    required WorldClock clock,
  })  : _campaignRepository = campaignRepository,
        _worldRepository = worldRepository,
        _idGenerator = idGenerator,
        _clock = clock;

  final CampaignRepository _campaignRepository;
  final WorldRepository _worldRepository;
  final WorldEntityIdGenerator _idGenerator;
  final WorldClock _clock;

  Future<World> call({
    required String campaignId,
    required String name,
    WorldMetadata? metadata,
  }) async {
    final normalizedCampaignId = campaignId.trim();
    final campaign = await _campaignRepository.getById(normalizedCampaignId);
    if (campaign == null) {
      throw CampaignNotFoundException(normalizedCampaignId);
    }
    if (campaign.isArchived) {
      throw StateError('Archived campaigns cannot receive new worlds.');
    }

    final now = _clock().toUtc();
    final world = World(
      id: _idGenerator(),
      campaignId: normalizedCampaignId,
      name: name,
      createdAt: now,
      updatedAt: now,
      metadata: metadata,
    );
    await _worldRepository.saveWorld(world);
    return world;
  }
}

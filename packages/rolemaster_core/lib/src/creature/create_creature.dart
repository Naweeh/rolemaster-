import '../campaign/campaign_not_found_exception.dart';
import '../campaign/campaign_repository.dart';
import '../world/world_repository.dart';
import 'creature.dart';
import 'creature_metadata.dart';
import 'creature_placement.dart';
import 'creature_placement_validator.dart';
import 'creature_repository.dart';
import 'creature_support.dart';

final class CreateCreature {
  CreateCreature({
    required CreatureRepository repository,
    required CampaignRepository campaignRepository,
    required WorldRepository worldRepository,
    required CreatureIdGenerator idGenerator,
    required CreatureClock clock,
  })  : _repository = repository,
        _campaignRepository = campaignRepository,
        _worldRepository = worldRepository,
        _idGenerator = idGenerator,
        _clock = clock;

  final CreatureRepository _repository;
  final CampaignRepository _campaignRepository;
  final WorldRepository _worldRepository;
  final CreatureIdGenerator _idGenerator;
  final CreatureClock _clock;

  Future<Creature> call({
    required String campaignId,
    required String name,
    required CreatureMetadata metadata,
    CreaturePlacement? placement,
  }) async {
    final normalizedCampaignId = campaignId.trim();
    if (normalizedCampaignId.isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'Creature campaignId cannot be empty.',
      );
    }

    final campaign = await _campaignRepository.getById(normalizedCampaignId);
    if (campaign == null) {
      throw CampaignNotFoundException(normalizedCampaignId);
    }
    if (campaign.isArchived) {
      throw StateError('Cannot create creatures in an archived campaign.');
    }

    final resolvedPlacement = placement ?? CreaturePlacement.unplaced();
    await validateCreaturePlacement(
      placement: resolvedPlacement,
      campaignId: normalizedCampaignId,
      worldRepository: _worldRepository,
    );

    final now = _clock().toUtc();
    final creature = Creature(
      id: _idGenerator(),
      campaignId: normalizedCampaignId,
      name: name,
      createdAt: now,
      updatedAt: now,
      metadata: metadata,
      placement: resolvedPlacement,
    );
    await _repository.save(creature);
    return creature;
  }
}

import '../campaign/campaign_not_found_exception.dart';
import '../campaign/campaign_repository.dart';
import '../world/world_repository.dart';
import 'npc.dart';
import 'npc_metadata.dart';
import 'npc_placement.dart';
import 'npc_placement_validator.dart';
import 'npc_repository.dart';
import 'npc_support.dart';

final class CreateNpc {
  CreateNpc({
    required NpcRepository repository,
    required CampaignRepository campaignRepository,
    required WorldRepository worldRepository,
    required NpcIdGenerator idGenerator,
    required NpcClock clock,
  })  : _repository = repository,
        _campaignRepository = campaignRepository,
        _worldRepository = worldRepository,
        _idGenerator = idGenerator,
        _clock = clock;

  final NpcRepository _repository;
  final CampaignRepository _campaignRepository;
  final WorldRepository _worldRepository;
  final NpcIdGenerator _idGenerator;
  final NpcClock _clock;

  Future<Npc> call({
    required String campaignId,
    required String name,
    required NpcMetadata metadata,
    NpcPlacement? placement,
  }) async {
    final normalizedCampaignId = campaignId.trim();
    if (normalizedCampaignId.isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'NPC campaignId cannot be empty.',
      );
    }

    final campaign = await _campaignRepository.getById(normalizedCampaignId);
    if (campaign == null) {
      throw CampaignNotFoundException(normalizedCampaignId);
    }
    if (campaign.isArchived) {
      throw StateError('Cannot create NPCs in an archived campaign.');
    }

    final resolvedPlacement = placement ?? NpcPlacement.unplaced();
    await validateNpcPlacement(
      placement: resolvedPlacement,
      campaignId: normalizedCampaignId,
      worldRepository: _worldRepository,
    );

    final now = _clock().toUtc();
    final npc = Npc(
      id: _idGenerator(),
      campaignId: normalizedCampaignId,
      name: name,
      createdAt: now,
      updatedAt: now,
      metadata: metadata,
      placement: resolvedPlacement,
    );
    await _repository.save(npc);
    return npc;
  }
}

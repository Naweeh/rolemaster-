import 'campaign.dart';
import 'campaign_configuration.dart';
import 'campaign_metadata.dart';
import 'campaign_repository.dart';

typedef CampaignIdGenerator = String Function();
typedef Clock = DateTime Function();

final class CreateCampaign {
  CreateCampaign({
    required CampaignRepository repository,
    required CampaignIdGenerator idGenerator,
    required Clock clock,
  })  : _repository = repository,
        _idGenerator = idGenerator,
        _clock = clock;

  final CampaignRepository _repository;
  final CampaignIdGenerator _idGenerator;
  final Clock _clock;

  Future<Campaign> call(
    String name, {
    CampaignMetadata? metadata,
    CampaignConfiguration? configuration,
  }) async {
    final now = _clock().toUtc();
    final campaign = Campaign(
      id: _idGenerator(),
      name: name,
      createdAt: now,
      updatedAt: now,
      metadata: metadata,
      configuration: configuration,
    );

    await _repository.save(campaign);
    return campaign;
  }
}

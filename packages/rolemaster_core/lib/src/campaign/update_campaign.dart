import 'campaign.dart';
import 'campaign_configuration.dart';
import 'campaign_metadata.dart';
import 'campaign_not_found_exception.dart';
import 'campaign_repository.dart';
import 'create_campaign.dart';

final class UpdateCampaign {
  UpdateCampaign({
    required CampaignRepository repository,
    required Clock clock,
  })  : _repository = repository,
        _clock = clock;

  final CampaignRepository _repository;
  final Clock _clock;

  Future<Campaign> call({
    required String id,
    String? name,
    CampaignMetadata? metadata,
    CampaignConfiguration? configuration,
  }) async {
    final normalizedId = id.trim();
    final campaign = await _repository.getById(normalizedId);
    if (campaign == null) {
      throw CampaignNotFoundException(normalizedId);
    }

    final updated = campaign.update(
      name: name,
      metadata: metadata,
      configuration: configuration,
      at: _clock(),
    );
    await _repository.save(updated);
    return updated;
  }
}

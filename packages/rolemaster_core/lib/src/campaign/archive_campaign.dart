import 'campaign.dart';
import 'campaign_not_found_exception.dart';
import 'campaign_repository.dart';
import 'create_campaign.dart';

final class ArchiveCampaign {
  ArchiveCampaign({
    required CampaignRepository repository,
    required Clock clock,
  }) : _repository = repository,
       _clock = clock;

  final CampaignRepository _repository;
  final Clock _clock;

  Future<Campaign> call(String id) async {
    final normalizedId = id.trim();
    final campaign = await _repository.getById(normalizedId);
    if (campaign == null) {
      throw CampaignNotFoundException(normalizedId);
    }

    final archived = campaign.archive(at: _clock());
    await _repository.save(archived);
    return archived;
  }
}

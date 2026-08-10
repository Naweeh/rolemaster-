import 'campaign.dart';
import 'campaign_not_found_exception.dart';
import 'campaign_repository.dart';
import 'create_campaign.dart';

final class RenameCampaign {
  RenameCampaign({
    required CampaignRepository repository,
    required Clock clock,
  }) : _repository = repository,
       _clock = clock;

  final CampaignRepository _repository;
  final Clock _clock;

  Future<Campaign> call({required String id, required String name}) async {
    final normalizedId = id.trim();
    final campaign = await _repository.getById(normalizedId);
    if (campaign == null) {
      throw CampaignNotFoundException(normalizedId);
    }

    final renamed = campaign.rename(name: name, at: _clock());
    await _repository.save(renamed);
    return renamed;
  }
}

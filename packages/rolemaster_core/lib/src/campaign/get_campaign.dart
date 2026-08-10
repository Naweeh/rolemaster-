import 'campaign.dart';
import 'campaign_not_found_exception.dart';
import 'campaign_repository.dart';

final class GetCampaign {
  GetCampaign({required CampaignRepository repository})
      : _repository = repository;

  final CampaignRepository _repository;

  Future<Campaign> call(String id) async {
    final campaign = await _repository.getById(id.trim());
    if (campaign == null) {
      throw CampaignNotFoundException(id.trim());
    }
    return campaign;
  }
}

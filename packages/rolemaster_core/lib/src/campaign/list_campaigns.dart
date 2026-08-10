import 'campaign.dart';
import 'campaign_repository.dart';

final class ListCampaigns {
  ListCampaigns({required CampaignRepository repository})
    : _repository = repository;

  final CampaignRepository _repository;

  Future<List<Campaign>> call({bool includeArchived = false}) {
    return _repository.getAll(includeArchived: includeArchived);
  }
}

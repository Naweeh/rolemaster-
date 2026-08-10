import 'campaign.dart';

abstract interface class CampaignRepository {
  Future<List<Campaign>> getAll();

  Future<void> save(Campaign campaign);
}

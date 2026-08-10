import 'campaign.dart';

abstract interface class CampaignRepository {
  Future<Campaign?> getById(String id);

  Future<List<Campaign>> getAll({bool includeArchived = false});

  Future<void> save(Campaign campaign);
}

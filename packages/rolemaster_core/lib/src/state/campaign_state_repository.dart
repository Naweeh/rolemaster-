import 'campaign_state.dart';

abstract interface class CampaignStateRepository {
  Future<CampaignState?> getByCampaignId(String campaignId);

  Future<void> save(CampaignState state);
}

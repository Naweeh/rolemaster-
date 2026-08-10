import 'campaign_state.dart';

abstract interface class CampaignStateRepository {
  Future<CampaignState?> getByCampaignId(String campaignId);

  Future<bool> save(
    CampaignState state, {
    required int expectedRevision,
  });
}

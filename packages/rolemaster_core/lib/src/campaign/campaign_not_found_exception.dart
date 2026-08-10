final class CampaignNotFoundException implements Exception {
  CampaignNotFoundException(this.campaignId);

  final String campaignId;

  @override
  String toString() => 'Campaign not found: $campaignId';
}

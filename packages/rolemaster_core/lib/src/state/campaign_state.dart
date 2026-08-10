final class CampaignState {
  CampaignState({
    required String campaignId,
    required this.revision,
    DateTime? updatedAt,
  })  : campaignId = campaignId.trim(),
        updatedAt = updatedAt?.toUtc() {
    if (this.campaignId.isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'Campaign state campaignId cannot be empty.',
      );
    }
    if (revision < 0) {
      throw ArgumentError.value(
        revision,
        'revision',
        'Campaign state revision cannot be negative.',
      );
    }
    if (revision == 0 && this.updatedAt != null) {
      throw ArgumentError(
        'Initial Campaign state cannot have an updatedAt timestamp.',
      );
    }
    if (revision > 0 && this.updatedAt == null) {
      throw ArgumentError('Revised Campaign state requires updatedAt.');
    }
  }

  factory CampaignState.initial(String campaignId) {
    return CampaignState(campaignId: campaignId, revision: 0);
  }

  final String campaignId;
  final int revision;
  final DateTime? updatedAt;

  CampaignState advance(DateTime at) {
    final normalizedAt = at.toUtc();
    if (updatedAt != null && normalizedAt.isBefore(updatedAt!)) {
      throw ArgumentError.value(
        at,
        'at',
        'Campaign state cannot move backwards in time.',
      );
    }
    return CampaignState(
      campaignId: campaignId,
      revision: revision + 1,
      updatedAt: normalizedAt,
    );
  }
}

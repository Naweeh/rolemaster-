import 'campaign_moment.dart';

final class CampaignTimeline {
  CampaignTimeline({
    required String campaignId,
    required String calendarId,
    required this.currentMoment,
  })  : campaignId = campaignId.trim(),
        calendarId = calendarId.trim() {
    if (this.campaignId.isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'Timeline campaignId cannot be empty.',
      );
    }
    if (this.calendarId.isEmpty) {
      throw ArgumentError.value(
        calendarId,
        'calendarId',
        'Timeline calendarId cannot be empty.',
      );
    }
  }

  final String campaignId;
  final String calendarId;
  final CampaignMoment currentMoment;

  CampaignTimeline moveTo(CampaignMoment moment) {
    return CampaignTimeline(
      campaignId: campaignId,
      calendarId: calendarId,
      currentMoment: moment,
    );
  }
}

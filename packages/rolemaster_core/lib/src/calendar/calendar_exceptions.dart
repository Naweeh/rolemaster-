final class CalendarNotFoundException implements Exception {
  CalendarNotFoundException(this.calendarId);

  final String calendarId;

  @override
  String toString() => 'Calendar not found: $calendarId';
}

final class CampaignTimelineNotFoundException implements Exception {
  CampaignTimelineNotFoundException(this.campaignId);

  final String campaignId;

  @override
  String toString() => 'Campaign timeline not found: $campaignId';
}

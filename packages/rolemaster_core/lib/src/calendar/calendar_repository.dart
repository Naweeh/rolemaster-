import 'calendar_definition.dart';
import 'campaign_timeline.dart';
import 'temporal_event.dart';

abstract interface class CalendarRepository {
  Future<CalendarDefinition?> getCalendarById(String id);

  Future<void> saveCalendar(CalendarDefinition calendar);

  Future<CampaignTimeline?> getTimelineForCampaign(String campaignId);

  Future<void> saveTimeline(CampaignTimeline timeline);

  Future<TemporalEvent?> getEventById(String id);

  Future<List<TemporalEvent>> getEventsForCampaign(String campaignId);

  Future<void> saveEvent(TemporalEvent event);
}

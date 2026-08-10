import 'calendar_engine.dart';
import 'calendar_exceptions.dart';
import 'calendar_repository.dart';
import 'campaign_moment.dart';

final class AdvanceCampaignTime {
  AdvanceCampaignTime({
    required CalendarRepository repository,
    CalendarEngine engine = const CalendarEngine(),
  })  : _repository = repository,
        _engine = engine;

  final CalendarRepository _repository;
  final CalendarEngine _engine;

  Future<CampaignMoment> call({
    required String campaignId,
    required CampaignDuration duration,
  }) async {
    final normalizedCampaignId = campaignId.trim();
    final timeline = await _repository.getTimelineForCampaign(
      normalizedCampaignId,
    );
    if (timeline == null) {
      throw CampaignTimelineNotFoundException(normalizedCampaignId);
    }

    final calendar = await _repository.getCalendarById(timeline.calendarId);
    if (calendar == null) {
      throw CalendarNotFoundException(timeline.calendarId);
    }

    final nextMoment = _engine.advance(
      calendar,
      timeline.currentMoment,
      duration,
    );
    await _repository.saveTimeline(timeline.moveTo(nextMoment));
    return nextMoment;
  }
}

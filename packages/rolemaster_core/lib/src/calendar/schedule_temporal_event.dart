import 'calendar_engine.dart';
import 'calendar_exceptions.dart';
import 'calendar_repository.dart';
import 'calendar_support.dart';
import 'campaign_moment.dart';
import 'temporal_event.dart';

final class ScheduleTemporalEvent {
  ScheduleTemporalEvent({
    required CalendarRepository repository,
    required CalendarEntityIdGenerator idGenerator,
    CalendarEngine engine = const CalendarEngine(),
  })  : _repository = repository,
        _idGenerator = idGenerator,
        _engine = engine;

  final CalendarRepository _repository;
  final CalendarEntityIdGenerator _idGenerator;
  final CalendarEngine _engine;

  Future<TemporalEvent> call({
    required String campaignId,
    required String title,
    required CampaignMoment scheduledAt,
    String? notes,
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

    _engine.validateMoment(calendar, scheduledAt);
    if (_engine.compare(calendar, scheduledAt, timeline.currentMoment) < 0) {
      throw ArgumentError('Temporal event cannot be scheduled in the past.');
    }

    final event = TemporalEvent(
      id: _idGenerator(),
      campaignId: normalizedCampaignId,
      calendarId: timeline.calendarId,
      title: title,
      scheduledAt: scheduledAt,
      notes: notes,
    );
    await _repository.saveEvent(event);
    return event;
  }
}

final class ListDueTemporalEvents {
  ListDueTemporalEvents({
    required CalendarRepository repository,
    CalendarEngine engine = const CalendarEngine(),
  })  : _repository = repository,
        _engine = engine;

  final CalendarRepository _repository;
  final CalendarEngine _engine;

  Future<List<TemporalEvent>> call(String campaignId) async {
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

    final events = await _repository.getEventsForCampaign(normalizedCampaignId);
    final due = events
        .where(
          (event) =>
              event.calendarId == timeline.calendarId &&
              _engine.compare(
                    calendar,
                    event.scheduledAt,
                    timeline.currentMoment,
                  ) <=
                  0,
        )
        .toList(growable: false);
    due.sort(
      (left, right) =>
          _engine.compare(calendar, left.scheduledAt, right.scheduledAt),
    );
    return due;
  }
}

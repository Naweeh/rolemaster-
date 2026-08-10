import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  group('CalendarEngine', () {
    const engine = CalendarEngine();

    test('advances time across custom month and year boundaries', () {
      final calendar = _calendar();
      const start = CampaignMoment(
        year: 1,
        month: 2,
        day: 2,
        hour: 9,
        minute: 90,
      );

      final result = engine.advance(
        calendar,
        start,
        const CampaignDuration(minutes: 20),
      );

      expect(result.year, 2);
      expect(result.month, 1);
      expect(result.day, 1);
      expect(result.hour, 0);
      expect(result.minute, 10);
    });

    test('round trips a custom campaign moment through absolute minutes', () {
      final calendar = _calendar();
      const moment = CampaignMoment(
        year: 4,
        month: 2,
        day: 1,
        hour: 3,
        minute: 25,
      );

      final absolute = engine.toAbsoluteMinutes(calendar, moment);
      final restored = engine.fromAbsoluteMinutes(calendar, absolute);

      expect(restored.year, moment.year);
      expect(restored.month, moment.month);
      expect(restored.day, moment.day);
      expect(restored.hour, moment.hour);
      expect(restored.minute, moment.minute);
    });

    test('uses custom weekday names independently of Gregorian calendar', () {
      final calendar = _calendar();

      expect(
        engine.weekdayName(
          calendar,
          const CampaignMoment(year: 1, month: 1, day: 1),
        ),
        'Sol',
      );
      expect(
        engine.weekdayName(
          calendar,
          const CampaignMoment(year: 1, month: 1, day: 2),
        ),
        'Luna',
      );
    });

    test('rejects dates that do not exist in the custom calendar', () {
      final calendar = _calendar();

      expect(
        () => engine.validateMoment(
          calendar,
          const CampaignMoment(year: 1, month: 2, day: 3),
        ),
        throwsArgumentError,
      );
    });
  });

  group('Campaign timeline use cases', () {
    test('initializes a custom calendar for an active campaign', () async {
      final campaigns = _MemoryCampaignRepository(<Campaign>[
        _campaign('campaign-1'),
      ]);
      final calendars = _MemoryCalendarRepository();
      final useCase = InitializeCampaignTimeline(
        campaignRepository: campaigns,
        calendarRepository: calendars,
      );

      final timeline = await useCase(
        campaignId: ' campaign-1 ',
        calendar: _calendar(),
        initialMoment: const CampaignMoment(year: 1, month: 1, day: 1),
      );

      expect(timeline.campaignId, 'campaign-1');
      expect(timeline.calendarId, 'calendar-1');
      expect(await calendars.getCalendarById('calendar-1'), isNotNull);
      expect(await calendars.getTimelineForCampaign('campaign-1'), isNotNull);
    });

    test('advances and persists campaign time', () async {
      final calendars = _MemoryCalendarRepository(
        calendars: <CalendarDefinition>[_calendar()],
        timelines: <CampaignTimeline>[
          CampaignTimeline(
            campaignId: 'campaign-1',
            calendarId: 'calendar-1',
            currentMoment: const CampaignMoment(
              year: 1,
              month: 1,
              day: 3,
              hour: 9,
              minute: 50,
            ),
          ),
        ],
      );
      final useCase = AdvanceCampaignTime(repository: calendars);

      final next = await useCase(
        campaignId: 'campaign-1',
        duration: const CampaignDuration(minutes: 20),
      );

      expect(next.month, 2);
      expect(next.day, 1);
      expect(next.hour, 0);
      expect(next.minute, 10);
      final persisted = await calendars.getTimelineForCampaign('campaign-1');
      expect(persisted?.currentMoment.month, 2);
    });

    test('schedules events and exposes them when campaign time reaches them',
        () async {
      final calendars = _MemoryCalendarRepository(
        calendars: <CalendarDefinition>[_calendar()],
        timelines: <CampaignTimeline>[
          CampaignTimeline(
            campaignId: 'campaign-1',
            calendarId: 'calendar-1',
            currentMoment: const CampaignMoment(year: 1, month: 1, day: 1),
          ),
        ],
      );
      final schedule = ScheduleTemporalEvent(
        repository: calendars,
        idGenerator: () => 'event-1',
      );
      final due = ListDueTemporalEvents(repository: calendars);
      final advance = AdvanceCampaignTime(repository: calendars);

      await schedule(
        campaignId: 'campaign-1',
        title: 'Llega la caravana',
        scheduledAt: const CampaignMoment(year: 1, month: 1, day: 2),
      );

      expect(await due('campaign-1'), isEmpty);

      await advance(
        campaignId: 'campaign-1',
        duration: const CampaignDuration(days: 1),
      );

      final events = await due('campaign-1');
      expect(events, hasLength(1));
      expect(events.single.id, 'event-1');
    });

    test('does not schedule an event before current campaign time', () async {
      final calendars = _MemoryCalendarRepository(
        calendars: <CalendarDefinition>[_calendar()],
        timelines: <CampaignTimeline>[
          CampaignTimeline(
            campaignId: 'campaign-1',
            calendarId: 'calendar-1',
            currentMoment: const CampaignMoment(year: 2, month: 1, day: 1),
          ),
        ],
      );
      final useCase = ScheduleTemporalEvent(
        repository: calendars,
        idGenerator: () => 'event-1',
      );

      await expectLater(
        useCase(
          campaignId: 'campaign-1',
          title: 'Pasado',
          scheduledAt: const CampaignMoment(year: 1, month: 1, day: 1),
        ),
        throwsArgumentError,
      );
    });
  });
}

CalendarDefinition _calendar() {
  return CalendarDefinition(
    id: 'calendar-1',
    name: 'Calendario de prueba',
    months: <CalendarMonth>[
      CalendarMonth(name: 'Alba', days: 3),
      CalendarMonth(name: 'Ocaso', days: 2),
    ],
    weekdays: <String>['Sol', 'Luna', 'Estrella'],
    hoursPerDay: 10,
    minutesPerHour: 100,
  );
}

Campaign _campaign(String id) {
  return Campaign(
    id: id,
    name: 'Campaign',
    createdAt: DateTime.utc(2026, 8, 10),
  );
}

final class _MemoryCampaignRepository implements CampaignRepository {
  _MemoryCampaignRepository(Iterable<Campaign> campaigns) {
    for (final campaign in campaigns) {
      _campaigns[campaign.id] = campaign;
    }
  }

  final Map<String, Campaign> _campaigns = <String, Campaign>{};

  @override
  Future<Campaign?> getById(String id) async => _campaigns[id];

  @override
  Future<List<Campaign>> getAll({bool includeArchived = false}) async {
    return _campaigns.values
        .where((campaign) => includeArchived || !campaign.isArchived)
        .toList(growable: false);
  }

  @override
  Future<void> save(Campaign campaign) async {
    _campaigns[campaign.id] = campaign;
  }
}

final class _MemoryCalendarRepository implements CalendarRepository {
  _MemoryCalendarRepository({
    Iterable<CalendarDefinition> calendars = const <CalendarDefinition>[],
    Iterable<CampaignTimeline> timelines = const <CampaignTimeline>[],
    Iterable<TemporalEvent> events = const <TemporalEvent>[],
  }) {
    for (final calendar in calendars) {
      _calendars[calendar.id] = calendar;
    }
    for (final timeline in timelines) {
      _timelines[timeline.campaignId] = timeline;
    }
    for (final event in events) {
      _events[event.id] = event;
    }
  }

  final Map<String, CalendarDefinition> _calendars =
      <String, CalendarDefinition>{};
  final Map<String, CampaignTimeline> _timelines = <String, CampaignTimeline>{};
  final Map<String, TemporalEvent> _events = <String, TemporalEvent>{};

  @override
  Future<CalendarDefinition?> getCalendarById(String id) async => _calendars[id];

  @override
  Future<TemporalEvent?> getEventById(String id) async => _events[id];

  @override
  Future<List<TemporalEvent>> getEventsForCampaign(String campaignId) async {
    return _events.values
        .where((event) => event.campaignId == campaignId)
        .toList(growable: false);
  }

  @override
  Future<CampaignTimeline?> getTimelineForCampaign(String campaignId) async {
    return _timelines[campaignId];
  }

  @override
  Future<void> saveCalendar(CalendarDefinition calendar) async {
    _calendars[calendar.id] = calendar;
  }

  @override
  Future<void> saveEvent(TemporalEvent event) async {
    _events[event.id] = event;
  }

  @override
  Future<void> saveTimeline(CampaignTimeline timeline) async {
    _timelines[timeline.campaignId] = timeline;
  }
}

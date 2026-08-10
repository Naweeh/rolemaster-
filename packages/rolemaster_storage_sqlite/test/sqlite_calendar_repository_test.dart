import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteCalendarRepository', () {
    test('persists custom calendar, timeline and temporal events after reopening',
        () async {
      final directory = await Directory.systemTemp.createTemp(
        'rolemaster_calendar_sqlite_',
      );
      final databasePath =
          '${directory.path}${Platform.pathSeparator}calendar.db';
      addTearDown(() => directory.delete(recursive: true));

      final campaignRepository = SqliteCampaignRepository.open(databasePath);
      await campaignRepository.save(
        Campaign(
          id: 'campaign-1',
          name: 'Campaña',
          createdAt: DateTime.utc(2026, 8, 10, 10),
        ),
      );
      campaignRepository.close();

      final writer = SqliteCalendarRepository.open(databasePath);
      final calendar = _calendar();
      final timeline = CampaignTimeline(
        campaignId: 'campaign-1',
        calendarId: calendar.id,
        currentMoment: const CampaignMoment(
          year: 3,
          month: 2,
          day: 2,
          hour: 4,
          minute: 25,
        ),
      );
      final laterEvent = TemporalEvent(
        id: 'event-2',
        campaignId: 'campaign-1',
        calendarId: calendar.id,
        title: 'Evento posterior',
        scheduledAt: const CampaignMoment(
          year: 3,
          month: 2,
          day: 2,
          hour: 7,
          minute: 0,
        ),
        notes: '  Nota persistente  ',
      );
      final earlierEvent = TemporalEvent(
        id: 'event-1',
        campaignId: 'campaign-1',
        calendarId: calendar.id,
        title: 'Evento anterior',
        scheduledAt: const CampaignMoment(
          year: 3,
          month: 2,
          day: 2,
          hour: 5,
          minute: 0,
        ),
      );

      await writer.saveCalendar(calendar);
      await writer.saveTimeline(timeline);
      await writer.saveEvent(laterEvent);
      await writer.saveEvent(earlierEvent);
      writer.close();

      final reader = SqliteCalendarRepository.open(databasePath);
      final loadedCalendar = await reader.getCalendarById('calendar-1');
      final loadedTimeline = await reader.getTimelineForCampaign('campaign-1');
      final events = await reader.getEventsForCampaign('campaign-1');
      final loadedEvent = await reader.getEventById('event-2');
      reader.close();

      expect(loadedCalendar, isNotNull);
      expect(loadedCalendar!.name, 'Calendario de campaña');
      expect(loadedCalendar.months, hasLength(2));
      expect(loadedCalendar.months.first.name, 'Alba');
      expect(loadedCalendar.months.first.days, 3);
      expect(loadedCalendar.weekdays, <String>['Sol', 'Luna', 'Estrella']);
      expect(loadedCalendar.hoursPerDay, 10);
      expect(loadedCalendar.minutesPerHour, 100);
      expect(loadedCalendar.startingWeekdayIndex, 1);

      expect(loadedTimeline, isNotNull);
      expect(loadedTimeline!.calendarId, 'calendar-1');
      expect(loadedTimeline.currentMoment.year, 3);
      expect(loadedTimeline.currentMoment.month, 2);
      expect(loadedTimeline.currentMoment.day, 2);
      expect(loadedTimeline.currentMoment.hour, 4);
      expect(loadedTimeline.currentMoment.minute, 25);

      expect(events.map((event) => event.id), <String>['event-1', 'event-2']);
      expect(loadedEvent, isNotNull);
      expect(loadedEvent!.notes, 'Nota persistente');
    });

    test('upserts timeline and event state', () async {
      final directory = await Directory.systemTemp.createTemp(
        'rolemaster_calendar_upsert_',
      );
      final databasePath =
          '${directory.path}${Platform.pathSeparator}calendar-upsert.db';
      addTearDown(() => directory.delete(recursive: true));

      final campaignRepository = SqliteCampaignRepository.open(databasePath);
      await campaignRepository.save(
        Campaign(
          id: 'campaign-1',
          name: 'Campaña',
          createdAt: DateTime.utc(2026, 8, 10, 10),
        ),
      );
      campaignRepository.close();

      final repository = SqliteCalendarRepository.open(databasePath);
      await repository.saveCalendar(_calendar());
      await repository.saveTimeline(
        CampaignTimeline(
          campaignId: 'campaign-1',
          calendarId: 'calendar-1',
          currentMoment: const CampaignMoment(year: 1, month: 1, day: 1),
        ),
      );
      await repository.saveTimeline(
        CampaignTimeline(
          campaignId: 'campaign-1',
          calendarId: 'calendar-1',
          currentMoment: const CampaignMoment(year: 2, month: 1, day: 2),
        ),
      );
      await repository.saveEvent(
        TemporalEvent(
          id: 'event-1',
          campaignId: 'campaign-1',
          calendarId: 'calendar-1',
          title: 'Original',
          scheduledAt: const CampaignMoment(year: 2, month: 1, day: 2),
        ),
      );
      await repository.saveEvent(
        TemporalEvent(
          id: 'event-1',
          campaignId: 'campaign-1',
          calendarId: 'calendar-1',
          title: 'Actualizado',
          scheduledAt: const CampaignMoment(year: 2, month: 1, day: 3),
        ),
      );

      final timeline = await repository.getTimelineForCampaign('campaign-1');
      final events = await repository.getEventsForCampaign('campaign-1');
      repository.close();

      expect(timeline?.currentMoment.year, 2);
      expect(timeline?.currentMoment.day, 2);
      expect(events, hasLength(1));
      expect(events.single.title, 'Actualizado');
      expect(events.single.scheduledAt.day, 3);
    });

    test('migrates schema v3 to v4 without losing Campaign or World data',
        () async {
      final directory = await Directory.systemTemp.createTemp(
        'rolemaster_calendar_migration_',
      );
      final databasePath =
          '${directory.path}${Platform.pathSeparator}legacy-v3.db';
      addTearDown(() => directory.delete(recursive: true));

      _createLegacyV3Database(databasePath);

      final calendarRepository = SqliteCalendarRepository.open(databasePath);
      await calendarRepository.saveCalendar(_calendar());
      await calendarRepository.saveTimeline(
        CampaignTimeline(
          campaignId: 'campaign-legacy',
          calendarId: 'calendar-1',
          currentMoment: const CampaignMoment(year: 7, month: 1, day: 2),
        ),
      );
      calendarRepository.close();

      final campaignRepository = SqliteCampaignRepository.open(databasePath);
      final campaign = await campaignRepository.getById('campaign-legacy');
      campaignRepository.close();

      final worldRepository = SqliteWorldRepository.open(databasePath);
      final world = await worldRepository.getWorldById('world-legacy');
      worldRepository.close();

      final migrated = sqlite3.open(databasePath);
      final version = migrated.select('PRAGMA user_version').single;
      final calendarRows = migrated.select('SELECT id FROM calendars');
      final timelineRows = migrated.select(
        'SELECT campaign_id FROM campaign_timelines',
      );
      migrated.close();

      expect(campaign, isNotNull);
      expect(campaign!.name, 'Campaña anterior');
      expect(world, isNotNull);
      expect(world!.name, 'Mundo anterior');
      expect(version['user_version'], SqliteCalendarRepository.schemaVersion);
      expect(calendarRows.single['id'], 'calendar-1');
      expect(timelineRows.single['campaign_id'], 'campaign-legacy');
    });
  });
}

CalendarDefinition _calendar() {
  return CalendarDefinition(
    id: 'calendar-1',
    name: 'Calendario de campaña',
    months: <CalendarMonth>[
      CalendarMonth(name: 'Alba', days: 3),
      CalendarMonth(name: 'Ocaso', days: 2),
    ],
    weekdays: <String>['Sol', 'Luna', 'Estrella'],
    hoursPerDay: 10,
    minutesPerHour: 100,
    startingWeekdayIndex: 1,
  );
}

void _createLegacyV3Database(String path) {
  final database = sqlite3.open(path);
  database.execute('PRAGMA foreign_keys = ON');
  database.execute('''
    CREATE TABLE campaigns (
      id TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      archived_at INTEGER,
      description TEXT,
      tags_json TEXT NOT NULL DEFAULT '[]',
      ai_enabled INTEGER NOT NULL DEFAULT 1 CHECK (ai_enabled IN (0, 1)),
      voice_enabled INTEGER NOT NULL DEFAULT 1 CHECK (voice_enabled IN (0, 1)),
      audio_enabled INTEGER NOT NULL DEFAULT 1 CHECK (audio_enabled IN (0, 1))
    ) STRICT
  ''');
  database.execute('''
    CREATE TABLE worlds (
      id TEXT NOT NULL PRIMARY KEY,
      campaign_id TEXT NOT NULL,
      name TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      description TEXT,
      tags_json TEXT NOT NULL DEFAULT '[]',
      FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE RESTRICT
    ) STRICT
  ''');
  database.execute('''
    CREATE TABLE regions (
      id TEXT NOT NULL PRIMARY KEY,
      world_id TEXT NOT NULL,
      name TEXT NOT NULL,
      parent_region_id TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      description TEXT,
      tags_json TEXT NOT NULL DEFAULT '[]',
      FOREIGN KEY (world_id) REFERENCES worlds(id) ON DELETE CASCADE,
      FOREIGN KEY (parent_region_id) REFERENCES regions(id) ON DELETE RESTRICT
    ) STRICT
  ''');
  database.execute('''
    CREATE TABLE locations (
      id TEXT NOT NULL PRIMARY KEY,
      world_id TEXT NOT NULL,
      name TEXT NOT NULL,
      region_id TEXT,
      parent_location_id TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      description TEXT,
      tags_json TEXT NOT NULL DEFAULT '[]',
      FOREIGN KEY (world_id) REFERENCES worlds(id) ON DELETE CASCADE,
      FOREIGN KEY (region_id) REFERENCES regions(id) ON DELETE RESTRICT,
      FOREIGN KEY (parent_location_id) REFERENCES locations(id) ON DELETE RESTRICT
    ) STRICT
  ''');

  final createdAt = DateTime.utc(2026, 8, 10, 10).millisecondsSinceEpoch;
  database.execute(
    '''
    INSERT INTO campaigns (
      id,
      name,
      created_at,
      updated_at,
      archived_at,
      description,
      tags_json,
      ai_enabled,
      voice_enabled,
      audio_enabled
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    <Object?>[
      'campaign-legacy',
      'Campaña anterior',
      createdAt,
      createdAt,
      null,
      null,
      '[]',
      1,
      1,
      1,
    ],
  );
  database.execute(
    '''
    INSERT INTO worlds (
      id,
      campaign_id,
      name,
      created_at,
      updated_at,
      description,
      tags_json
    ) VALUES (?, ?, ?, ?, ?, ?, ?)
    ''',
    <Object?>[
      'world-legacy',
      'campaign-legacy',
      'Mundo anterior',
      createdAt,
      createdAt,
      null,
      '[]',
    ],
  );
  database.execute('PRAGMA user_version = 3');
  database.close();
}

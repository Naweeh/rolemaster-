import 'dart:convert';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_schema.dart';

final class SqliteCalendarRepository implements CalendarRepository {
  SqliteCalendarRepository._(this._database) {
    initializeRolemasterSqliteSchema(_database);
  }

  factory SqliteCalendarRepository.open(String path) {
    return SqliteCalendarRepository._(sqlite3.open(path));
  }

  factory SqliteCalendarRepository.inMemory() {
    return SqliteCalendarRepository._(sqlite3.openInMemory());
  }

  static const int schemaVersion = rolemasterSqliteSchemaVersion;

  final Database _database;

  @override
  Future<CalendarDefinition?> getCalendarById(String id) async {
    final rows = _database.select(
      '''
      SELECT
        id,
        name,
        months_json,
        weekdays_json,
        hours_per_day,
        minutes_per_hour,
        starting_weekday_index
      FROM calendars
      WHERE id = ?
      LIMIT 1
      ''',
      <Object?>[id.trim()],
    );
    return rows.isEmpty ? null : _calendarFromRow(rows.single);
  }

  @override
  Future<void> saveCalendar(CalendarDefinition calendar) async {
    _database.execute(
      '''
      INSERT INTO calendars (
        id,
        name,
        months_json,
        weekdays_json,
        hours_per_day,
        minutes_per_hour,
        starting_weekday_index
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        months_json = excluded.months_json,
        weekdays_json = excluded.weekdays_json,
        hours_per_day = excluded.hours_per_day,
        minutes_per_hour = excluded.minutes_per_hour,
        starting_weekday_index = excluded.starting_weekday_index
      ''',
      <Object?>[
        calendar.id,
        calendar.name,
        _encodeMonths(calendar.months),
        jsonEncode(calendar.weekdays),
        calendar.hoursPerDay,
        calendar.minutesPerHour,
        calendar.startingWeekdayIndex,
      ],
    );
  }

  @override
  Future<CampaignTimeline?> getTimelineForCampaign(String campaignId) async {
    final rows = _database.select(
      '''
      SELECT
        campaign_id,
        calendar_id,
        current_year,
        current_month,
        current_day,
        current_hour,
        current_minute
      FROM campaign_timelines
      WHERE campaign_id = ?
      LIMIT 1
      ''',
      <Object?>[campaignId.trim()],
    );
    return rows.isEmpty ? null : _timelineFromRow(rows.single);
  }

  @override
  Future<void> saveTimeline(CampaignTimeline timeline) async {
    final moment = timeline.currentMoment;
    _database.execute(
      '''
      INSERT INTO campaign_timelines (
        campaign_id,
        calendar_id,
        current_year,
        current_month,
        current_day,
        current_hour,
        current_minute
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(campaign_id) DO UPDATE SET
        calendar_id = excluded.calendar_id,
        current_year = excluded.current_year,
        current_month = excluded.current_month,
        current_day = excluded.current_day,
        current_hour = excluded.current_hour,
        current_minute = excluded.current_minute
      ''',
      <Object?>[
        timeline.campaignId,
        timeline.calendarId,
        moment.year,
        moment.month,
        moment.day,
        moment.hour,
        moment.minute,
      ],
    );
  }

  @override
  Future<TemporalEvent?> getEventById(String id) async {
    final rows = _database.select(
      '''
      SELECT
        id,
        campaign_id,
        calendar_id,
        title,
        scheduled_year,
        scheduled_month,
        scheduled_day,
        scheduled_hour,
        scheduled_minute,
        notes
      FROM temporal_events
      WHERE id = ?
      LIMIT 1
      ''',
      <Object?>[id.trim()],
    );
    return rows.isEmpty ? null : _eventFromRow(rows.single);
  }

  @override
  Future<List<TemporalEvent>> getEventsForCampaign(String campaignId) async {
    final rows = _database.select(
      '''
      SELECT
        id,
        campaign_id,
        calendar_id,
        title,
        scheduled_year,
        scheduled_month,
        scheduled_day,
        scheduled_hour,
        scheduled_minute,
        notes
      FROM temporal_events
      WHERE campaign_id = ?
      ORDER BY
        scheduled_year ASC,
        scheduled_month ASC,
        scheduled_day ASC,
        scheduled_hour ASC,
        scheduled_minute ASC,
        id ASC
      ''',
      <Object?>[campaignId.trim()],
    );
    return rows.map(_eventFromRow).toList(growable: false);
  }

  @override
  Future<void> saveEvent(TemporalEvent event) async {
    final moment = event.scheduledAt;
    _database.execute(
      '''
      INSERT INTO temporal_events (
        id,
        campaign_id,
        calendar_id,
        title,
        scheduled_year,
        scheduled_month,
        scheduled_day,
        scheduled_hour,
        scheduled_minute,
        notes
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        campaign_id = excluded.campaign_id,
        calendar_id = excluded.calendar_id,
        title = excluded.title,
        scheduled_year = excluded.scheduled_year,
        scheduled_month = excluded.scheduled_month,
        scheduled_day = excluded.scheduled_day,
        scheduled_hour = excluded.scheduled_hour,
        scheduled_minute = excluded.scheduled_minute,
        notes = excluded.notes
      ''',
      <Object?>[
        event.id,
        event.campaignId,
        event.calendarId,
        event.title,
        moment.year,
        moment.month,
        moment.day,
        moment.hour,
        moment.minute,
        event.notes,
      ],
    );
  }

  void close() {
    _database.close();
  }

  CalendarDefinition _calendarFromRow(Row row) {
    return CalendarDefinition(
      id: row['id'] as String,
      name: row['name'] as String,
      months: _decodeMonths(row['months_json'] as String),
      weekdays: _decodeWeekdays(row['weekdays_json'] as String),
      hoursPerDay: row['hours_per_day'] as int,
      minutesPerHour: row['minutes_per_hour'] as int,
      startingWeekdayIndex: row['starting_weekday_index'] as int,
    );
  }

  CampaignTimeline _timelineFromRow(Row row) {
    return CampaignTimeline(
      campaignId: row['campaign_id'] as String,
      calendarId: row['calendar_id'] as String,
      currentMoment: CampaignMoment(
        year: row['current_year'] as int,
        month: row['current_month'] as int,
        day: row['current_day'] as int,
        hour: row['current_hour'] as int,
        minute: row['current_minute'] as int,
      ),
    );
  }

  TemporalEvent _eventFromRow(Row row) {
    return TemporalEvent(
      id: row['id'] as String,
      campaignId: row['campaign_id'] as String,
      calendarId: row['calendar_id'] as String,
      title: row['title'] as String,
      scheduledAt: CampaignMoment(
        year: row['scheduled_year'] as int,
        month: row['scheduled_month'] as int,
        day: row['scheduled_day'] as int,
        hour: row['scheduled_hour'] as int,
        minute: row['scheduled_minute'] as int,
      ),
      notes: row['notes'] as String?,
    );
  }

  String _encodeMonths(List<CalendarMonth> months) {
    return jsonEncode(
      months
          .map(
            (month) => <String, Object>{
              'name': month.name,
              'days': month.days,
            },
          )
          .toList(growable: false),
    );
  }

  List<CalendarMonth> _decodeMonths(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! List) {
      throw StateError('Invalid Calendar months payload in Rolemaster database.');
    }

    return decoded.map((value) {
      if (value is! Map) {
        throw StateError(
          'Invalid Calendar month entry in Rolemaster database.',
        );
      }
      final name = value['name'];
      final days = value['days'];
      if (name is! String || days is! int) {
        throw StateError(
          'Invalid Calendar month entry in Rolemaster database.',
        );
      }
      return CalendarMonth(name: name, days: days);
    }).toList(growable: false);
  }

  List<String> _decodeWeekdays(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! List || decoded.any((value) => value is! String)) {
      throw StateError(
        'Invalid Calendar weekdays payload in Rolemaster database.',
      );
    }
    return decoded.cast<String>();
  }
}

import 'calendar_definition.dart';
import 'campaign_moment.dart';

final class CalendarEngine {
  const CalendarEngine();

  void validateMoment(CalendarDefinition calendar, CampaignMoment moment) {
    if (moment.year < 1) {
      throw ArgumentError.value(
          moment.year, 'year', 'Campaign year must be >= 1.');
    }
    if (moment.month < 1 || moment.month > calendar.months.length) {
      throw ArgumentError.value(
          moment.month, 'month', 'Campaign month is out of range.');
    }
    final month = calendar.months[moment.month - 1];
    if (moment.day < 1 || moment.day > month.days) {
      throw ArgumentError.value(
          moment.day, 'day', 'Campaign day is out of range.');
    }
    if (moment.hour < 0 || moment.hour >= calendar.hoursPerDay) {
      throw ArgumentError.value(
          moment.hour, 'hour', 'Campaign hour is out of range.');
    }
    if (moment.minute < 0 || moment.minute >= calendar.minutesPerHour) {
      throw ArgumentError.value(
        moment.minute,
        'minute',
        'Campaign minute is out of range.',
      );
    }
  }

  int toAbsoluteMinutes(CalendarDefinition calendar, CampaignMoment moment) {
    validateMoment(calendar, moment);
    final completedYears = moment.year - 1;
    var completedDays = completedYears * calendar.daysPerYear;
    for (var index = 0; index < moment.month - 1; index++) {
      completedDays += calendar.months[index].days;
    }
    completedDays += moment.day - 1;
    return completedDays * calendar.minutesPerDay +
        moment.hour * calendar.minutesPerHour +
        moment.minute;
  }

  CampaignMoment fromAbsoluteMinutes(
    CalendarDefinition calendar,
    int absoluteMinutes,
  ) {
    if (absoluteMinutes < 0) {
      throw ArgumentError.value(
        absoluteMinutes,
        'absoluteMinutes',
        'Campaign time cannot be before year 1.',
      );
    }
    final absoluteDay = absoluteMinutes ~/ calendar.minutesPerDay;
    final minuteOfDay = absoluteMinutes % calendar.minutesPerDay;
    final year = absoluteDay ~/ calendar.daysPerYear + 1;
    var dayOfYear = absoluteDay % calendar.daysPerYear;
    var monthIndex = 0;
    while (dayOfYear >= calendar.months[monthIndex].days) {
      dayOfYear -= calendar.months[monthIndex].days;
      monthIndex++;
    }
    return CampaignMoment(
      year: year,
      month: monthIndex + 1,
      day: dayOfYear + 1,
      hour: minuteOfDay ~/ calendar.minutesPerHour,
      minute: minuteOfDay % calendar.minutesPerHour,
    );
  }

  CampaignMoment advance(
    CalendarDefinition calendar,
    CampaignMoment moment,
    CampaignDuration duration,
  ) {
    duration.validate();
    final deltaMinutes = duration.days * calendar.minutesPerDay +
        duration.hours * calendar.minutesPerHour +
        duration.minutes;
    return fromAbsoluteMinutes(
      calendar,
      toAbsoluteMinutes(calendar, moment) + deltaMinutes,
    );
  }

  int compare(
    CalendarDefinition calendar,
    CampaignMoment left,
    CampaignMoment right,
  ) {
    return toAbsoluteMinutes(calendar, left).compareTo(
      toAbsoluteMinutes(calendar, right),
    );
  }

  int weekdayIndex(CalendarDefinition calendar, CampaignMoment moment) {
    final day = toAbsoluteMinutes(calendar, moment) ~/ calendar.minutesPerDay;
    return (calendar.startingWeekdayIndex + day) % calendar.weekdays.length;
  }

  String weekdayName(CalendarDefinition calendar, CampaignMoment moment) {
    return calendar.weekdays[weekdayIndex(calendar, moment)];
  }
}

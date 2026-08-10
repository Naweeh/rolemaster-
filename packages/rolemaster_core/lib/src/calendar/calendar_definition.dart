final class CalendarMonth {
  CalendarMonth({required String name, required this.days})
      : name = name.trim() {
    if (this.name.isEmpty) {
      throw ArgumentError.value(
          name, 'name', 'Calendar month name cannot be empty.');
    }
    if (days <= 0) {
      throw ArgumentError.value(days, 'days', 'Calendar month must have days.');
    }
  }

  final String name;
  final int days;
}

final class CalendarDefinition {
  CalendarDefinition({
    required String id,
    required String name,
    required Iterable<CalendarMonth> months,
    required Iterable<String> weekdays,
    this.hoursPerDay = 24,
    this.minutesPerHour = 60,
    this.startingWeekdayIndex = 0,
  })  : id = id.trim(),
        name = name.trim(),
        months = List<CalendarMonth>.unmodifiable(months),
        weekdays = List<String>.unmodifiable(
          weekdays.map((value) => value.trim()),
        ) {
    if (this.id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Calendar id cannot be empty.');
    }
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Calendar name cannot be empty.');
    }
    if (this.months.isEmpty) {
      throw ArgumentError('Calendar must define at least one month.');
    }
    if (this.weekdays.isEmpty || this.weekdays.any((value) => value.isEmpty)) {
      throw ArgumentError('Calendar must define non-empty weekday names.');
    }
    if (hoursPerDay <= 0) {
      throw ArgumentError.value(
        hoursPerDay,
        'hoursPerDay',
        'Calendar hoursPerDay must be positive.',
      );
    }
    if (minutesPerHour <= 0) {
      throw ArgumentError.value(
        minutesPerHour,
        'minutesPerHour',
        'Calendar minutesPerHour must be positive.',
      );
    }
    if (startingWeekdayIndex < 0 ||
        startingWeekdayIndex >= this.weekdays.length) {
      throw ArgumentError.value(
        startingWeekdayIndex,
        'startingWeekdayIndex',
        'Calendar starting weekday is out of range.',
      );
    }
  }

  final String id;
  final String name;
  final List<CalendarMonth> months;
  final List<String> weekdays;
  final int hoursPerDay;
  final int minutesPerHour;
  final int startingWeekdayIndex;

  int get daysPerYear => months.fold<int>(0, (sum, month) => sum + month.days);
  int get minutesPerDay => hoursPerDay * minutesPerHour;
}

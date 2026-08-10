final class CampaignMoment {
  const CampaignMoment({
    required this.year,
    required this.month,
    required this.day,
    this.hour = 0,
    this.minute = 0,
  });

  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
}

final class CampaignDuration {
  const CampaignDuration({
    this.days = 0,
    this.hours = 0,
    this.minutes = 0,
  });

  final int days;
  final int hours;
  final int minutes;

  bool get isZero => days == 0 && hours == 0 && minutes == 0;

  void validate() {
    if (days < 0 || hours < 0 || minutes < 0) {
      throw ArgumentError('Campaign duration cannot be negative.');
    }
  }
}

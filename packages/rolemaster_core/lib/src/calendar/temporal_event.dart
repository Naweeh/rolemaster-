import 'campaign_moment.dart';

final class TemporalEvent {
  TemporalEvent({
    required String id,
    required String campaignId,
    required String calendarId,
    required String title,
    required this.scheduledAt,
    String? notes,
  })  : id = id.trim(),
        campaignId = campaignId.trim(),
        calendarId = calendarId.trim(),
        title = title.trim(),
        notes = _normalizeOptionalText(notes) {
    if (this.id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Temporal event id cannot be empty.');
    }
    if (this.campaignId.isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'Temporal event campaignId cannot be empty.',
      );
    }
    if (this.calendarId.isEmpty) {
      throw ArgumentError.value(
        calendarId,
        'calendarId',
        'Temporal event calendarId cannot be empty.',
      );
    }
    if (this.title.isEmpty) {
      throw ArgumentError.value(
        title,
        'title',
        'Temporal event title cannot be empty.',
      );
    }
  }

  final String id;
  final String campaignId;
  final String calendarId;
  final String title;
  final CampaignMoment scheduledAt;
  final String? notes;

  static String? _normalizeOptionalText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

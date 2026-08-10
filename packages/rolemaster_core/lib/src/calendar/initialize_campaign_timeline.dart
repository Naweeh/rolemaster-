import '../campaign/campaign_not_found_exception.dart';
import '../campaign/campaign_repository.dart';
import 'calendar_definition.dart';
import 'calendar_engine.dart';
import 'calendar_repository.dart';
import 'campaign_moment.dart';
import 'campaign_timeline.dart';

final class InitializeCampaignTimeline {
  InitializeCampaignTimeline({
    required CampaignRepository campaignRepository,
    required CalendarRepository calendarRepository,
    CalendarEngine engine = const CalendarEngine(),
  })  : _campaignRepository = campaignRepository,
        _calendarRepository = calendarRepository,
        _engine = engine;

  final CampaignRepository _campaignRepository;
  final CalendarRepository _calendarRepository;
  final CalendarEngine _engine;

  Future<CampaignTimeline> call({
    required String campaignId,
    required CalendarDefinition calendar,
    required CampaignMoment initialMoment,
  }) async {
    final normalizedCampaignId = campaignId.trim();
    final campaign = await _campaignRepository.getById(normalizedCampaignId);
    if (campaign == null) {
      throw CampaignNotFoundException(normalizedCampaignId);
    }
    if (campaign.isArchived) {
      throw StateError('Archived campaigns cannot initialize a timeline.');
    }

    _engine.validateMoment(calendar, initialMoment);
    final timeline = CampaignTimeline(
      campaignId: normalizedCampaignId,
      calendarId: calendar.id,
      currentMoment: initialMoment,
    );

    await _calendarRepository.saveCalendar(calendar);
    await _calendarRepository.saveTimeline(timeline);
    return timeline;
  }
}

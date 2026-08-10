abstract final class DomainEventTypes {
  static const String campaignCreated = 'campaign.created';
  static const String campaignUpdated = 'campaign.updated';
  static const String campaignArchived = 'campaign.archived';

  static const String worldCreated = 'world.created';
  static const String worldRegionAdded = 'world.region_added';
  static const String worldLocationAdded = 'world.location_added';

  static const String timeAdvanced = 'time.advanced';
  static const String temporalEventDue = 'time.temporal_event_due';

  static const String combatStarted = 'combat.started';
  static const String voiceRecognized = 'voice.recognized';
  static const String audioCueRequested = 'audio.cue_requested';
}

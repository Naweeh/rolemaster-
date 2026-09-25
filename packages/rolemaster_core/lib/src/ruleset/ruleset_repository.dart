import 'ruleset_content_migration.dart';
import 'ruleset_models.dart';

abstract interface class RulesetRepository {
  Future<RulesetPackage?> getPackage({
    required String rulesetId,
    required String version,
  });

  Future<List<RulesetPackage>> getAvailablePackages();
}

abstract interface class RulesetPublisher {
  Future<void> publish(RulesetPackage package);
}

abstract interface class CampaignRulesetRepository {
  Future<CampaignRulesetState?> getForCampaign(String campaignId);

  Future<void> save(CampaignRulesetState state);

  Future<void> migrate({
    required CampaignRulesetState expected,
    required CampaignRulesetState next,
    required RulesetContentMigration contentMigration,
  });
}

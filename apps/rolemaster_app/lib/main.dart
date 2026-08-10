import 'package:flutter/material.dart';
import 'package:rolemaster_core/rolemaster_core.dart';

import 'src/app/rolemaster_app.dart';
import 'src/infrastructure/demo_rulesets.dart';
import 'src/infrastructure/in_memory_campaign_repository.dart';
import 'src/infrastructure/in_memory_ruleset_repository.dart';

void main() {
  final CampaignRepository campaignRepository = InMemoryCampaignRepository();
  final RulesetRepository rulesetRepository =
      InMemoryRulesetRepository(buildDemoRulesets());
  final CampaignRulesetRepository campaignRulesetRepository =
      InMemoryCampaignRulesetRepository();

  runApp(
    RolemasterApp(
      campaignRepository: campaignRepository,
      rulesetRepository: rulesetRepository,
      campaignRulesetRepository: campaignRulesetRepository,
    ),
  );
}

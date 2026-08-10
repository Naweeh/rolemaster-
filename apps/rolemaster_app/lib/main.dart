import 'package:flutter/material.dart';
import 'package:rolemaster_core/rolemaster_core.dart';

import 'src/app/rolemaster_app.dart';
import 'src/infrastructure/in_memory_campaign_repository.dart';
import 'src/infrastructure/in_memory_ruleset_repository.dart';
import 'src/infrastructure/manual_alpha_rulesets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final CampaignRepository campaignRepository = InMemoryCampaignRepository();
  final manualRulesets = buildManualAlphaRulesets();
  final RulesetRepository rulesetRepository =
      InMemoryRulesetRepository(manualRulesets);
  final CampaignRulesetRepository campaignRulesetRepository =
      InMemoryCampaignRulesetRepository();

  final package = manualRulesets.single;
  final campaign = Campaign(
    id: 'visual-alpha-dnd',
    name: 'Frontera B/X · Visual Alpha',
    createdAt: DateTime.utc(2026, 8, 10, 20, 30),
  );
  await campaignRepository.save(campaign);

  final initializeRuleset = InitializeCampaignRuleset(
    campaignRepository: campaignRepository,
    rulesetRepository: rulesetRepository,
    campaignRulesetRepository: campaignRulesetRepository,
    clock: () => DateTime.utc(2026, 8, 10, 20, 30),
  );
  await initializeRuleset(
    campaignId: campaign.id,
    rulesetId: package.manifest.id,
    rulesetVersion: package.manifest.version,
    activeModuleIds: package.manifest.defaultModuleIds,
  );

  runApp(
    RolemasterApp(
      campaignRepository: campaignRepository,
      rulesetRepository: rulesetRepository,
      campaignRulesetRepository: campaignRulesetRepository,
    ),
  );
}

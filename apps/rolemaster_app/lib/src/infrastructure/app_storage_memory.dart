import 'package:rolemaster_core/rolemaster_core.dart';

import '../features/visual_alpha/visual_alpha_character_profile.dart';
import 'app_storage.dart';
import 'in_memory_campaign_repository.dart';
import 'in_memory_character_repository.dart';
import 'in_memory_ruleset_repository.dart';

Future<AppStorage> openAppStorage(RulesetPackage package) async {
  final storage = AppStorage(
    campaigns: InMemoryCampaignRepository(),
    characters: InMemoryCharacterRepository(),
    characterProfiles: InMemoryVisualAlphaCharacterProfileRepository(),
    rulesets: InMemoryRulesetRepository(<RulesetPackage>[package]),
    campaignRulesets: InMemoryCampaignRulesetRepository(),
  );
  await initializeVisualAlphaCampaign(storage, package);
  return storage;
}

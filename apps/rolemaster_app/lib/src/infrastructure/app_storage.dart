import 'package:rolemaster_core/rolemaster_core.dart';

final class AppStorage {
  AppStorage({
    required this.campaigns,
    required this.characters,
    required this.rulesets,
    required this.campaignRulesets,
    void Function()? close,
  }) : _close = close;

  final CampaignRepository campaigns;
  final CharacterRepository characters;
  final RulesetRepository rulesets;
  final CampaignRulesetRepository campaignRulesets;
  final void Function()? _close;
  bool _closed = false;

  void close() {
    if (_closed) return;
    _close?.call();
    _closed = true;
  }
}

Future<void> initializeVisualAlphaCampaign(
  AppStorage storage,
  RulesetPackage package,
) async {
  const campaignId = 'visual-alpha-dnd';
  final existing = await storage.campaigns.getById(campaignId);
  if (existing == null) {
    await storage.campaigns.save(
      Campaign(
        id: campaignId,
        name: 'Frontera B/X · Visual Alpha',
        createdAt: DateTime.utc(2026, 8, 10, 20, 30),
      ),
    );
  }
  if (await storage.campaignRulesets.getForCampaign(campaignId) != null) {
    return;
  }
  final initializeRuleset = InitializeCampaignRuleset(
    campaignRepository: storage.campaigns,
    rulesetRepository: storage.rulesets,
    campaignRulesetRepository: storage.campaignRulesets,
    clock: () => DateTime.utc(2026, 8, 10, 20, 30),
  );
  await initializeRuleset(
    campaignId: campaignId,
    rulesetId: package.manifest.id,
    rulesetVersion: package.manifest.version,
    activeModuleIds: package.manifest.defaultModuleIds,
  );
}

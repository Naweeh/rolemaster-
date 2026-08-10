import '../campaign/campaign_not_found_exception.dart';
import '../campaign/campaign_repository.dart';
import 'ruleset_exceptions.dart';
import 'ruleset_models.dart';
import 'ruleset_repository.dart';

typedef RulesetClock = DateTime Function();

final class InitializeCampaignRuleset {
  InitializeCampaignRuleset({
    required this.campaignRepository,
    required this.rulesetRepository,
    required this.campaignRulesetRepository,
    required this.clock,
  });

  final CampaignRepository campaignRepository;
  final RulesetRepository rulesetRepository;
  final CampaignRulesetRepository campaignRulesetRepository;
  final RulesetClock clock;

  Future<CampaignRulesetState> call({
    required String campaignId,
    required String rulesetId,
    required String rulesetVersion,
    Iterable<String>? activeModuleIds,
  }) async {
    final normalizedCampaignId = campaignId.trim();
    final campaign = await campaignRepository.getById(normalizedCampaignId);
    if (campaign == null) {
      throw CampaignNotFoundException(normalizedCampaignId);
    }
    if (campaign.isArchived) {
      throw StateError('Archived campaigns cannot initialize a ruleset.');
    }

    final existing = await campaignRulesetRepository.getForCampaign(
      normalizedCampaignId,
    );
    if (existing != null) {
      throw CampaignRulesetAlreadyInitializedException(normalizedCampaignId);
    }

    final normalizedRulesetId = rulesetId.trim();
    final normalizedVersion = rulesetVersion.trim();
    final package = await rulesetRepository.getPackage(
      rulesetId: normalizedRulesetId,
      version: normalizedVersion,
    );
    if (package == null) {
      throw RulesetNotFoundException(normalizedRulesetId, normalizedVersion);
    }

    final selected = activeModuleIds == null
        ? package.manifest.defaultModuleIds
        : _normalizeModules(activeModuleIds);
    _validateModules(package.manifest, selected);

    final now = clock().toUtc();
    final state = CampaignRulesetState(
      binding: CampaignRulesetBinding(
        campaignId: normalizedCampaignId,
        rulesetId: package.manifest.id,
        rulesetVersion: package.manifest.version,
        activeModuleIds: selected,
        boundAt: now,
      ),
      overlay: CampaignRulesOverlay.clean(
        campaignId: normalizedCampaignId,
        updatedAt: now,
      ),
    );
    await campaignRulesetRepository.save(state);
    return state;
  }

  List<String> _normalizeModules(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isNotEmpty && seen.add(normalized)) {
        result.add(normalized);
      }
    }
    return result;
  }

  void _validateModules(RulesetManifest manifest, Iterable<String> selected) {
    final selectedSet = selected.toSet();
    final available = manifest.modules.map((module) => module.id).toSet();

    for (final moduleId in selectedSet) {
      if (!available.contains(moduleId)) {
        throw UnknownRulesetModuleException(moduleId);
      }
    }
    for (final requiredId in manifest.requiredModuleIds) {
      if (!selectedSet.contains(requiredId)) {
        throw RequiredRulesetModuleMissingException(requiredId);
      }
    }
  }
}

import '../campaign/campaign_not_found_exception.dart';
import '../campaign/campaign_repository.dart';
import 'ruleset_exceptions.dart';
import 'ruleset_models.dart';
import 'ruleset_repository.dart';

/// An explicit, validated change of a campaign's pinned package version.
final class MigrateCampaignRuleset {
  MigrateCampaignRuleset({
    required this.campaignRepository,
    required this.rulesetRepository,
    required this.campaignRulesetRepository,
    required this.clock,
  });

  final CampaignRepository campaignRepository;
  final RulesetRepository rulesetRepository;
  final CampaignRulesetRepository campaignRulesetRepository;
  final DateTime Function() clock;

  Future<CampaignRulesetState> call({
    required String campaignId,
    required String targetRulesetId,
    required String targetVersion,
    required String expectedSourceVersion,
    required bool preserveOverlay,
    Iterable<String>? activeModuleIds,
  }) async {
    final id = campaignId.trim();
    final campaign = await campaignRepository.getById(id);
    if (campaign == null) {
      throw CampaignNotFoundException(id);
    }
    if (campaign.isArchived) {
      throw StateError('Archived campaigns cannot migrate rulesets.');
    }
    final current = await campaignRulesetRepository.getForCampaign(id);
    if (current == null) {
      throw CampaignRulesetNotInitializedException(id);
    }
    if (current.binding.rulesetVersion != expectedSourceVersion.trim()) {
      throw StateError(
          'Campaign ruleset changed since migration was requested.');
    }
    final source = await rulesetRepository.getPackage(
      rulesetId: current.binding.rulesetId,
      version: current.binding.rulesetVersion,
    );
    final target = await rulesetRepository.getPackage(
      rulesetId: targetRulesetId.trim(),
      version: targetVersion.trim(),
    );
    if (source == null) {
      throw RulesetNotFoundException(
          current.binding.rulesetId, current.binding.rulesetVersion);
    }
    if (target == null) {
      throw RulesetNotFoundException(targetRulesetId, targetVersion);
    }
    if (source.manifest.systemId != target.manifest.systemId ||
        source.manifest.id != target.manifest.id ||
        source.manifest.version == target.manifest.version) {
      throw StateError(
          'Migration requires a different version of the same ruleset.');
    }
    final selected = activeModuleIds == null
        ? current.binding.activeModuleIds
        : activeModuleIds.map((value) => value.trim()).toList();
    final unique = selected.toSet();
    if (selected.any((value) => value.isEmpty) ||
        unique.length != selected.length) {
      throw ArgumentError('Migration modules must be unique and nonempty.');
    }
    final available =
        target.manifest.modules.map((module) => module.id).toSet();
    for (final module in unique) {
      if (!available.contains(module)) {
        throw UnknownRulesetModuleException(module);
      }
    }
    for (final module in target.manifest.requiredModuleIds) {
      if (!unique.contains(module)) {
        throw RequiredRulesetModuleMissingException(module);
      }
    }
    final overrides =
        preserveOverlay ? current.overlay.overrides : const <String, Object?>{};
    if (preserveOverlay &&
        overrides.keys.any((key) => !target.data.containsKey(key))) {
      throw StateError('Overlay has keys absent from the target ruleset.');
    }
    final now = clock().toUtc();
    final next = CampaignRulesetState(
      binding: CampaignRulesetBinding(
        campaignId: id,
        rulesetId: target.manifest.id,
        rulesetVersion: target.manifest.version,
        activeModuleIds: selected,
        boundAt: now,
      ),
      overlay: CampaignRulesOverlay(
        campaignId: id,
        updatedAt: now,
        overrides: overrides,
      ),
    );
    await campaignRulesetRepository.migrate(
      expected: current.binding,
      next: next,
    );
    return next;
  }
}

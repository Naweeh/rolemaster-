import 'effective_ruleset.dart';
import 'ruleset_exceptions.dart';
import 'ruleset_repository.dart';

final class ResolveEffectiveRuleset {
  ResolveEffectiveRuleset({
    required RulesetRepository rulesetRepository,
    required CampaignRulesetRepository campaignRulesetRepository,
  })  : _rulesetRepository = rulesetRepository,
        _campaignRulesetRepository = campaignRulesetRepository;

  final RulesetRepository _rulesetRepository;
  final CampaignRulesetRepository _campaignRulesetRepository;

  Future<EffectiveRuleset> call(String campaignId) async {
    final normalizedCampaignId = campaignId.trim();
    if (normalizedCampaignId.isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'Campaign id cannot be empty.',
      );
    }

    final state = await _campaignRulesetRepository.getForCampaign(
      normalizedCampaignId,
    );
    if (state == null) {
      throw CampaignRulesetNotInitializedException(normalizedCampaignId);
    }
    if (state.binding.campaignId != normalizedCampaignId ||
        state.overlay.campaignId != normalizedCampaignId) {
      throw RulesetBindingMismatchException(
        'Stored state does not belong to campaign $normalizedCampaignId.',
      );
    }

    final package = await _rulesetRepository.getPackage(
      rulesetId: state.binding.rulesetId,
      version: state.binding.rulesetVersion,
    );
    if (package == null) {
      throw RulesetNotFoundException(
        state.binding.rulesetId,
        state.binding.rulesetVersion,
      );
    }
    if (package.manifest.id != state.binding.rulesetId ||
        package.manifest.version != state.binding.rulesetVersion) {
      throw RulesetBindingMismatchException(
        'Repository returned ${package.manifest.id}@${package.manifest.version} '
        'for binding ${state.binding.rulesetId}@${state.binding.rulesetVersion}.',
      );
    }

    _validateModules(
      available: package.manifest.modules.map((module) => module.id).toSet(),
      required: package.manifest.requiredModuleIds.toSet(),
      active: state.binding.activeModuleIds,
    );

    return EffectiveRuleset(
      campaignId: normalizedCampaignId,
      package: package,
      activeModuleIds: state.binding.activeModuleIds,
      overlay: state.overlay,
    );
  }

  void _validateModules({
    required Set<String> available,
    required Set<String> required,
    required Iterable<String> active,
  }) {
    final selected = active.toSet();
    for (final moduleId in selected) {
      if (!available.contains(moduleId)) {
        throw UnknownRulesetModuleException(moduleId);
      }
    }
    for (final moduleId in required) {
      if (!selected.contains(moduleId)) {
        throw RequiredRulesetModuleMissingException(moduleId);
      }
    }
  }
}

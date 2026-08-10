import 'ruleset_exceptions.dart';
import 'ruleset_models.dart';
import 'ruleset_repository.dart';

final class ResetCampaignRules {
  ResetCampaignRules({
    required this.repository,
    required this.clock,
  });

  final CampaignRulesetRepository repository;
  final DateTime Function() clock;

  Future<CampaignRulesetState> call(String campaignId) async {
    final normalizedCampaignId = campaignId.trim();
    final current = await repository.getForCampaign(normalizedCampaignId);
    if (current == null) {
      throw CampaignRulesetNotInitializedException(normalizedCampaignId);
    }

    final reset = CampaignRulesetState(
      binding: current.binding,
      overlay: CampaignRulesOverlay.clean(
        campaignId: normalizedCampaignId,
        updatedAt: clock().toUtc(),
      ),
    );
    await repository.save(reset);
    return reset;
  }
}

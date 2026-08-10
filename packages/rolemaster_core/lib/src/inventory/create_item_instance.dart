import '../campaign/campaign_not_found_exception.dart';
import '../campaign/campaign_repository.dart';
import '../ruleset/ruleset_exceptions.dart';
import '../ruleset/ruleset_repository.dart';
import 'inventory_exceptions.dart';
import 'item_instance.dart';
import 'item_instance_repository.dart';
import 'item_placement.dart';
import 'ruleset_item_catalog.dart';

typedef ItemIdGenerator = String Function();
typedef InventoryClock = DateTime Function();

final class CreateItemInstance {
  CreateItemInstance({
    required CampaignRepository campaignRepository,
    required RulesetRepository rulesetRepository,
    required CampaignRulesetRepository campaignRulesetRepository,
    required ItemInstanceRepository itemRepository,
    required ItemIdGenerator idGenerator,
    required InventoryClock clock,
  })  : _campaignRepository = campaignRepository,
        _rulesetRepository = rulesetRepository,
        _campaignRulesetRepository = campaignRulesetRepository,
        _itemRepository = itemRepository,
        _idGenerator = idGenerator,
        _clock = clock;

  final CampaignRepository _campaignRepository;
  final RulesetRepository _rulesetRepository;
  final CampaignRulesetRepository _campaignRulesetRepository;
  final ItemInstanceRepository _itemRepository;
  final ItemIdGenerator _idGenerator;
  final InventoryClock _clock;

  Future<ItemInstance> call({
    required String campaignId,
    String? definitionId,
    String? customName,
    int quantity = 1,
    ItemPlacement? placement,
    String? notes,
  }) async {
    final campaign = await _campaignRepository.getById(campaignId);
    if (campaign == null) {
      throw CampaignNotFoundException(campaignId);
    }

    final normalizedDefinitionId = _optional(definitionId);
    if (normalizedDefinitionId != null) {
      await _validateDefinition(campaign.id, normalizedDefinitionId);
    }

    final id = _idGenerator();
    final resolvedPlacement = placement ?? ItemPlacement.unassigned();
    await _validateContainer(
      campaignId: campaign.id,
      itemId: id,
      placement: resolvedPlacement,
    );

    final now = _clock().toUtc();
    final item = ItemInstance(
      id: id,
      campaignId: campaign.id,
      definitionId: normalizedDefinitionId,
      customName: customName,
      quantity: quantity,
      placement: resolvedPlacement,
      notes: notes,
      createdAt: now,
    );
    await _itemRepository.save(item);
    return item;
  }

  Future<void> _validateDefinition(String campaignId, String definitionId) async {
    final campaignRuleset =
        await _campaignRulesetRepository.getForCampaign(campaignId);
    if (campaignRuleset == null) {
      throw CampaignRulesetNotInitializedException(campaignId);
    }

    final package = await _rulesetRepository.getPackage(
      rulesetId: campaignRuleset.binding.rulesetId,
      version: campaignRuleset.binding.rulesetVersion,
    );
    if (package == null) {
      throw RulesetNotFoundException(
        campaignRuleset.binding.rulesetId,
        campaignRuleset.binding.rulesetVersion,
      );
    }

    final definition = RulesetItemCatalog.fromPackage(package).getById(
      definitionId,
    );
    if (definition == null) {
      throw ItemDefinitionNotFoundException(definitionId);
    }
    final moduleId = definition.moduleId;
    if (moduleId != null &&
        !campaignRuleset.binding.activeModuleIds.contains(moduleId)) {
      throw ItemModuleInactiveException(definition.id, moduleId);
    }
  }

  Future<void> _validateContainer({
    required String campaignId,
    required String itemId,
    required ItemPlacement placement,
  }) async {
    final containerId = placement.containerItemId;
    if (containerId == null) {
      return;
    }
    if (containerId == itemId) {
      throw ItemContainmentCycleException(itemId, containerId);
    }
    final container = await _itemRepository.getById(containerId);
    if (container == null) {
      throw ItemInstanceNotFoundException(containerId);
    }
    if (container.campaignId != campaignId) {
      throw CrossCampaignItemContainerException(itemId, containerId);
    }
  }
}

String? _optional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

final class InvalidRulesetItemCatalogException implements Exception {
  InvalidRulesetItemCatalogException(this.message);

  final String message;

  @override
  String toString() => 'Invalid ruleset item catalog: $message';
}

final class DuplicateItemDefinitionException implements Exception {
  DuplicateItemDefinitionException(this.itemId);

  final String itemId;

  @override
  String toString() => 'Duplicate item definition: $itemId';
}

final class UnknownItemModuleException implements Exception {
  UnknownItemModuleException(this.itemId, this.moduleId);

  final String itemId;
  final String moduleId;

  @override
  String toString() => 'Item $itemId references unknown module: $moduleId';
}

final class ItemDefinitionNotFoundException implements Exception {
  ItemDefinitionNotFoundException(this.itemId);

  final String itemId;

  @override
  String toString() => 'Item definition not found: $itemId';
}

final class ItemModuleInactiveException implements Exception {
  ItemModuleInactiveException(this.itemId, this.moduleId);

  final String itemId;
  final String moduleId;

  @override
  String toString() => 'Item $itemId requires inactive module: $moduleId';
}

final class ItemInstanceNotFoundException implements Exception {
  ItemInstanceNotFoundException(this.itemId);

  final String itemId;

  @override
  String toString() => 'Item instance not found: $itemId';
}

final class CrossCampaignItemContainerException implements Exception {
  CrossCampaignItemContainerException(this.itemId, this.containerItemId);

  final String itemId;
  final String containerItemId;

  @override
  String toString() =>
      'Item $itemId cannot use container $containerItemId from another campaign.';
}

final class ItemContainmentCycleException implements Exception {
  ItemContainmentCycleException(this.itemId, this.containerItemId);

  final String itemId;
  final String containerItemId;

  @override
  String toString() =>
      'Moving $itemId into $containerItemId would create a containment cycle.';
}

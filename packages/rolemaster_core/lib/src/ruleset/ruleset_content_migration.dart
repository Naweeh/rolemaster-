/// Explicit ID translations and valid destinations for campaign-owned records.
final class RulesetContentMigration {
  RulesetContentMigration({
    Map<String, String> skillIds = const <String, String>{},
    Map<String, String> itemDefinitionIds = const <String, String>{},
    required Iterable<String> availableTargetSkillIds,
    required Iterable<String> availableTargetItemIds,
  })  : skillIds = Map<String, String>.unmodifiable(skillIds),
        itemDefinitionIds = Map<String, String>.unmodifiable(itemDefinitionIds),
        availableTargetSkillIds = Set<String>.unmodifiable(
          availableTargetSkillIds,
        ),
        availableTargetItemIds = Set<String>.unmodifiable(
          availableTargetItemIds,
        ) {
    if (this.skillIds.entries.any(
          (entry) => entry.key.trim().isEmpty || entry.value.trim().isEmpty,
        ) ||
        this.itemDefinitionIds.entries.any(
          (entry) => entry.key.trim().isEmpty || entry.value.trim().isEmpty,
        )) {
      throw ArgumentError('Ruleset content mappings require nonempty IDs.');
    }
  }

  final Map<String, String> skillIds;
  final Map<String, String> itemDefinitionIds;
  final Set<String> availableTargetSkillIds;
  final Set<String> availableTargetItemIds;

  String skillId(String sourceId) => skillIds[sourceId] ?? sourceId;

  String itemDefinitionId(String sourceId) =>
      itemDefinitionIds[sourceId] ?? sourceId;
}

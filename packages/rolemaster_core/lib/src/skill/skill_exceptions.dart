final class InvalidRulesetSkillCatalogException implements Exception {
  InvalidRulesetSkillCatalogException(this.message);

  final String message;

  @override
  String toString() => 'Invalid ruleset skill catalog: $message';
}

final class DuplicateSkillDefinitionException implements Exception {
  DuplicateSkillDefinitionException(this.skillId);

  final String skillId;

  @override
  String toString() => 'Duplicate skill definition: $skillId';
}

final class UnknownSkillModuleException implements Exception {
  UnknownSkillModuleException(this.skillId, this.moduleId);

  final String skillId;
  final String moduleId;

  @override
  String toString() => 'Skill $skillId references unknown module: $moduleId';
}

final class SkillDefinitionNotFoundException implements Exception {
  SkillDefinitionNotFoundException(this.skillId);

  final String skillId;

  @override
  String toString() => 'Skill definition not found: $skillId';
}

final class SkillModuleInactiveException implements Exception {
  SkillModuleInactiveException(this.skillId, this.moduleId);

  final String skillId;
  final String moduleId;

  @override
  String toString() => 'Skill $skillId requires inactive module: $moduleId';
}

final class ArchivedCharacterSkillChangeException implements Exception {
  ArchivedCharacterSkillChangeException(this.characterId);

  final String characterId;

  @override
  String toString() => 'Archived character skills cannot be changed: $characterId';
}

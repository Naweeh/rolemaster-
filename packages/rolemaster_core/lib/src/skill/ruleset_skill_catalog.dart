import '../ruleset/ruleset_models.dart';
import 'skill_definition.dart';
import 'skill_exceptions.dart';

final class RulesetSkillCatalog {
  RulesetSkillCatalog(Iterable<SkillDefinition> definitions)
      : definitions = List<SkillDefinition>.unmodifiable(definitions) {
    final ids = <String>{};
    for (final definition in this.definitions) {
      if (!ids.add(definition.id)) {
        throw DuplicateSkillDefinitionException(definition.id);
      }
    }
  }

  factory RulesetSkillCatalog.fromPackage(RulesetPackage package) {
    final raw = package.data['skills'];
    if (raw == null) {
      return RulesetSkillCatalog(const <SkillDefinition>[]);
    }
    if (raw is! List) {
      throw InvalidRulesetSkillCatalogException(
        'Ruleset data key "skills" must be a list.',
      );
    }

    final knownModules = package.manifest.modules.map((module) => module.id).toSet();
    final definitions = <SkillDefinition>[];
    for (final value in raw) {
      if (value is! Map) {
        throw InvalidRulesetSkillCatalogException(
          'Each ruleset skill must be a JSON object.',
        );
      }
      final map = <String, Object?>{};
      for (final entry in value.entries) {
        if (entry.key is! String) {
          throw InvalidRulesetSkillCatalogException(
            'Ruleset skill keys must be strings.',
          );
        }
        map[entry.key as String] = entry.value;
      }

      final id = map['id'];
      final name = map['name'];
      if (id is! String || name is! String) {
        throw InvalidRulesetSkillCatalogException(
          'Each ruleset skill requires string id and name fields.',
        );
      }

      final moduleId = map['moduleId'];
      if (moduleId != null && moduleId is! String) {
        throw InvalidRulesetSkillCatalogException(
          'Skill $id has a non-string moduleId.',
        );
      }
      if (moduleId is String &&
          moduleId.trim().isNotEmpty &&
          !knownModules.contains(moduleId.trim())) {
        throw UnknownSkillModuleException(id, moduleId.trim());
      }

      final category = map['category'];
      final description = map['description'];
      if (category != null && category is! String) {
        throw InvalidRulesetSkillCatalogException(
          'Skill $id has a non-string category.',
        );
      }
      if (description != null && description is! String) {
        throw InvalidRulesetSkillCatalogException(
          'Skill $id has a non-string description.',
        );
      }

      final tagsRaw = map['tags'];
      final tags = <String>[];
      if (tagsRaw != null) {
        if (tagsRaw is! List || tagsRaw.any((value) => value is! String)) {
          throw InvalidRulesetSkillCatalogException(
            'Skill $id tags must be a list of strings.',
          );
        }
        tags.addAll(tagsRaw.cast<String>());
      }

      definitions.add(
        SkillDefinition(
          id: id,
          name: name,
          moduleId: moduleId as String?,
          category: category as String?,
          description: description as String?,
          tags: tags,
        ),
      );
    }

    return RulesetSkillCatalog(definitions);
  }

  final List<SkillDefinition> definitions;

  SkillDefinition? getById(String id) {
    final normalized = id.trim();
    for (final definition in definitions) {
      if (definition.id == normalized) {
        return definition;
      }
    }
    return null;
  }

  List<SkillDefinition> availableForModules(Iterable<String> moduleIds) {
    final active = moduleIds.map((id) => id.trim()).toSet();
    return List<SkillDefinition>.unmodifiable(
      definitions.where(
        (definition) =>
            definition.moduleId == null || active.contains(definition.moduleId),
      ),
    );
  }
}

import '../ruleset/ruleset_models.dart';
import 'inventory_exceptions.dart';
import 'item_definition.dart';

final class RulesetItemCatalog {
  RulesetItemCatalog(Iterable<ItemDefinition> definitions)
      : definitions = List<ItemDefinition>.unmodifiable(definitions) {
    final ids = <String>{};
    for (final definition in this.definitions) {
      if (!ids.add(definition.id)) {
        throw DuplicateItemDefinitionException(definition.id);
      }
    }
  }

  factory RulesetItemCatalog.fromPackage(RulesetPackage package) {
    final raw = package.data['items'];
    if (raw == null) {
      return RulesetItemCatalog(const <ItemDefinition>[]);
    }
    if (raw is! List) {
      throw InvalidRulesetItemCatalogException(
        'Ruleset data key "items" must be a list.',
      );
    }

    final knownModules =
        package.manifest.modules.map((module) => module.id).toSet();
    final definitions = <ItemDefinition>[];
    for (final value in raw) {
      if (value is! Map) {
        throw InvalidRulesetItemCatalogException(
          'Each ruleset item must be a JSON object.',
        );
      }

      final map = <String, Object?>{};
      for (final entry in value.entries) {
        if (entry.key is! String) {
          throw InvalidRulesetItemCatalogException(
            'Ruleset item keys must be strings.',
          );
        }
        map[entry.key as String] = entry.value;
      }

      final id = map['id'];
      final name = map['name'];
      if (id is! String || name is! String) {
        throw InvalidRulesetItemCatalogException(
          'Each ruleset item requires string id and name fields.',
        );
      }

      final moduleId = map['moduleId'];
      if (moduleId != null && moduleId is! String) {
        throw InvalidRulesetItemCatalogException(
          'Item $id has a non-string moduleId.',
        );
      }
      if (moduleId is String &&
          moduleId.trim().isNotEmpty &&
          !knownModules.contains(moduleId.trim())) {
        throw UnknownItemModuleException(id, moduleId.trim());
      }

      final category = map['category'];
      final description = map['description'];
      if (category != null && category is! String) {
        throw InvalidRulesetItemCatalogException(
          'Item $id has a non-string category.',
        );
      }
      if (description != null && description is! String) {
        throw InvalidRulesetItemCatalogException(
          'Item $id has a non-string description.',
        );
      }

      final tagsRaw = map['tags'];
      final tags = <String>[];
      if (tagsRaw != null) {
        if (tagsRaw is! List || tagsRaw.any((entry) => entry is! String)) {
          throw InvalidRulesetItemCatalogException(
            'Item $id tags must be a list of strings.',
          );
        }
        tags.addAll(tagsRaw.cast<String>());
      }

      final propertiesRaw = map['properties'];
      if (propertiesRaw != null && propertiesRaw is! Map) {
        throw InvalidRulesetItemCatalogException(
          'Item $id properties must be a JSON object.',
        );
      }
      final properties = <String, Object?>{};
      if (propertiesRaw is Map) {
        for (final entry in propertiesRaw.entries) {
          if (entry.key is! String) {
            throw InvalidRulesetItemCatalogException(
              'Item $id property keys must be strings.',
            );
          }
          properties[entry.key as String] = entry.value;
        }
      }

      definitions.add(
        ItemDefinition(
          id: id,
          name: name,
          moduleId: moduleId as String?,
          category: category as String?,
          description: description as String?,
          tags: tags,
          properties: properties,
        ),
      );
    }

    return RulesetItemCatalog(definitions);
  }

  final List<ItemDefinition> definitions;

  ItemDefinition? getById(String id) {
    final normalized = id.trim();
    for (final definition in definitions) {
      if (definition.id == normalized) {
        return definition;
      }
    }
    return null;
  }

  List<ItemDefinition> availableForModules(Iterable<String> moduleIds) {
    final active = moduleIds.map((id) => id.trim()).toSet();
    return List<ItemDefinition>.unmodifiable(
      definitions.where(
        (definition) =>
            definition.moduleId == null || active.contains(definition.moduleId),
      ),
    );
  }
}

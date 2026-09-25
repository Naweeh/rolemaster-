import '../ruleset/effective_ruleset.dart';

final class CombatStatDefinition {
  CombatStatDefinition({
    required String id,
    String? moduleId,
    this.min,
    this.max,
    this.initial,
  })  : id = id.trim(),
        moduleId = moduleId?.trim() {
    if (this.id.isEmpty || (this.moduleId != null && this.moduleId!.isEmpty)) {
      throw ArgumentError('Combat stat ID and module ID must be non-empty.');
    }
    if (min != null && max != null && min! > max!) {
      throw ArgumentError('Combat stat min cannot exceed max.');
    }
    if (initial != null && !accepts(initial!)) {
      throw ArgumentError('Combat stat initial value is out of range.');
    }
  }

  final String id;
  final String? moduleId;
  final int? min;
  final int? max;
  final int? initial;

  bool accepts(int value) =>
      (min == null || value >= min!) && (max == null || value <= max!);
}

final class RulesetCombatStatCatalog {
  RulesetCombatStatCatalog(this.ruleset);

  final EffectiveRuleset ruleset;

  List<CombatStatDefinition> get definitions {
    final raw = ruleset.data['combatStats'];
    if (raw == null) {
      return const <CombatStatDefinition>[];
    }
    if (raw is! List) {
      throw StateError('combatStats must be a list.');
    }
    final knownModules =
        ruleset.manifest.modules.map((module) => module.id).toSet();
    final seen = <String>{};
    final result = <CombatStatDefinition>[];
    for (final value in raw) {
      if (value is! Map || value.keys.any((key) => key is! String)) {
        throw StateError(
            'Each combat stat must be an object with string keys.');
      }
      final data = Map<String, Object?>.from(value);
      final id = data['id'];
      final moduleId = data['moduleId'];
      if (id is! String ||
          moduleId != null &&
              (moduleId is! String ||
                  !knownModules.contains(moduleId.trim()))) {
        throw StateError('Invalid combat stat ID or module.');
      }
      final min = _optionalInt(data['min'], 'min');
      final max = _optionalInt(data['max'], 'max');
      final initial = _optionalInt(data['initial'], 'initial');
      final definition = CombatStatDefinition(
        id: id,
        moduleId: moduleId as String?,
        min: min,
        max: max,
        initial: initial,
      );
      if (!seen.add(definition.id)) {
        throw StateError('Duplicate combat stat ID: ${definition.id}.');
      }
      result.add(definition);
    }
    return List<CombatStatDefinition>.unmodifiable(result);
  }

  List<CombatStatDefinition> get activeDefinitions =>
      List<CombatStatDefinition>.unmodifiable(
        definitions.where((item) =>
            item.moduleId == null || ruleset.isModuleActive(item.moduleId!)),
      );

  CombatStatDefinition requireActive(String statId) {
    for (final definition in definitions) {
      if (definition.id == statId.trim()) {
        if (definition.moduleId != null &&
            !ruleset.isModuleActive(definition.moduleId!)) {
          throw StateError('Combat stat requires an inactive module: $statId.');
        }
        return definition;
      }
    }
    throw StateError('Combat stat not found: $statId.');
  }
}

int? _optionalInt(Object? value, String field) {
  if (value == null) {
    return null;
  }
  if (value is! int) {
    throw StateError('Combat stat $field must be an integer.');
  }
  return value;
}

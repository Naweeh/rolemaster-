import '../ruleset/effective_ruleset.dart';
import 'resolution_rule_definition.dart';

final class RulesetResolutionCatalog {
  RulesetResolutionCatalog(this.ruleset);

  final EffectiveRuleset ruleset;

  List<ResolutionRuleDefinition> get definitions {
    final raw = ruleset.data['resolutionRules'];
    if (raw == null) {
      return const <ResolutionRuleDefinition>[];
    }
    if (raw is! List) {
      throw StateError('resolutionRules must be a list.');
    }

    final result = <ResolutionRuleDefinition>[];
    final seen = <String>{};
    for (final entry in raw) {
      if (entry is! Map) {
        throw StateError('Each resolution rule must be an object.');
      }
      final map = _stringMap(entry);
      final definition = ResolutionRuleDefinition(
        id: (map['id'] ?? '').toString(),
        kind: (map['kind'] ?? '').toString(),
        moduleId: map['moduleId']?.toString(),
        config: map['config'] == null
            ? const <String, Object?>{}
            : _stringMap(_requireMap(map['config'], 'config')),
      );
      if (!seen.add(definition.id)) {
        throw StateError('Duplicate resolution rule id: ${definition.id}.');
      }
      result.add(definition);
    }
    return List<ResolutionRuleDefinition>.unmodifiable(result);
  }

  ResolutionRuleDefinition? find(String ruleId) {
    final normalized = ruleId.trim();
    for (final definition in definitions) {
      if (definition.id == normalized) {
        return definition;
      }
    }
    return null;
  }
}

Map _requireMap(Object? value, String field) {
  if (value is! Map) {
    throw StateError('Resolution rule $field must be an object.');
  }
  return value;
}

Map<String, Object?> _stringMap(Map value) {
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw StateError('Resolution rule object keys must be strings.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

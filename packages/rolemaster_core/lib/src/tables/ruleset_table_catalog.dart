import '../ruleset/effective_ruleset.dart';
import 'ruleset_table.dart';
import 'ruleset_table_exceptions.dart';

final class RulesetTableCatalog {
  RulesetTableCatalog(this.ruleset);

  final EffectiveRuleset ruleset;

  List<RulesetTableDefinition> get definitions {
    final raw = ruleset.data['tables'];
    if (raw == null) {
      return const <RulesetTableDefinition>[];
    }
    if (raw is! List) {
      throw StateError('tables must be a list for RulesetTableCatalog.');
    }

    final result = <RulesetTableDefinition>[];
    final seen = <String>{};
    for (final rawDefinition in raw) {
      final map = _stringMap(_requiredMap(rawDefinition, 'table'));
      final id = (map['id'] ?? '').toString();
      if (!seen.add(id)) {
        throw StateError('Duplicate ruleset table id: $id.');
      }
      final gapPolicy = switch (map['gapPolicy']?.toString() ?? 'contiguous') {
        'contiguous' => RulesetTableGapPolicy.contiguous,
        'sparse' => RulesetTableGapPolicy.sparse,
        final value => throw StateError('Unknown table gapPolicy: $value.'),
      };
      final rawEntries = map['entries'];
      if (rawEntries is! List) {
        throw StateError('Table $id entries must be a list.');
      }
      final entries = rawEntries.map((rawEntry) {
        final entry = _stringMap(_requiredMap(rawEntry, 'entry'));
        return RulesetTableEntry(
          min: _requiredInt(entry['min'], 'entry.min'),
          max: _requiredInt(entry['max'], 'entry.max'),
          result: entry['result'] == null
              ? const <String, Object?>{}
              : _stringMap(_requiredMap(entry['result'], 'entry.result')),
        );
      });
      result.add(
        RulesetTableDefinition(
          id: id,
          moduleId: map['moduleId']?.toString(),
          gapPolicy: gapPolicy,
          entries: entries,
        ),
      );
    }
    return List<RulesetTableDefinition>.unmodifiable(result);
  }

  RulesetTableDefinition? find(String tableId) {
    final normalized = tableId.trim();
    for (final definition in definitions) {
      if (definition.id == normalized) {
        return definition;
      }
    }
    return null;
  }

  RulesetTableEntry? lookup({
    required String tableId,
    required int value,
  }) {
    final definition = find(tableId);
    if (definition == null) {
      throw RulesetTableNotFoundException(tableId.trim());
    }
    final moduleId = definition.moduleId;
    if (moduleId != null && !ruleset.isModuleActive(moduleId)) {
      throw RulesetTableModuleInactiveException(definition.id, moduleId);
    }
    return definition.lookup(value);
  }
}

Map _requiredMap(Object? value, String field) {
  if (value is! Map) {
    throw StateError('$field must be an object.');
  }
  return value;
}

Map<String, Object?> _stringMap(Map value) {
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw StateError('Table object keys must be strings.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

int _requiredInt(Object? value, String field) {
  if (value is! int) {
    throw StateError('$field must be an integer.');
  }
  return value;
}

enum RulesetTableGapPolicy {
  contiguous,
  sparse,
}

final class RulesetTableEntry {
  RulesetTableEntry({
    required this.min,
    required this.max,
    Map<String, Object?> result = const <String, Object?>{},
  }) : result = Map<String, Object?>.unmodifiable(result) {
    if (min > max) {
      throw ArgumentError('Table entry min cannot be greater than max.');
    }
  }

  final int min;
  final int max;
  final Map<String, Object?> result;

  bool contains(int value) => value >= min && value <= max;
}

final class RulesetTableDefinition {
  RulesetTableDefinition({
    required String id,
    String? moduleId,
    RulesetTableGapPolicy gapPolicy = RulesetTableGapPolicy.contiguous,
    required Iterable<RulesetTableEntry> entries,
  })  : id = _required(id, 'id'),
        moduleId = _optional(moduleId),
        gapPolicy = gapPolicy,
        entries = _validatedEntries(entries, gapPolicy);

  final String id;
  final String? moduleId;
  final RulesetTableGapPolicy gapPolicy;
  final List<RulesetTableEntry> entries;

  RulesetTableEntry? lookup(int value) {
    for (final entry in entries) {
      if (entry.contains(value)) {
        return entry;
      }
    }
    return null;
  }
}

List<RulesetTableEntry> _validatedEntries(
  Iterable<RulesetTableEntry> values,
  RulesetTableGapPolicy gapPolicy,
) {
  final sorted = values.toList()
    ..sort((left, right) => left.min.compareTo(right.min));
  if (sorted.isEmpty) {
    throw ArgumentError('Ruleset table must contain at least one entry.');
  }

  for (var index = 1; index < sorted.length; index++) {
    final previous = sorted[index - 1];
    final current = sorted[index];
    if (current.min <= previous.max) {
      throw ArgumentError('Ruleset table ranges cannot overlap.');
    }
    if (gapPolicy == RulesetTableGapPolicy.contiguous &&
        current.min != previous.max + 1) {
      throw ArgumentError('Contiguous ruleset table cannot contain gaps.');
    }
  }
  return List<RulesetTableEntry>.unmodifiable(sorted);
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, '$field cannot be empty.');
  }
  return normalized;
}

String? _optional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

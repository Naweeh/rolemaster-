final class RulesetTableNotFoundException implements Exception {
  RulesetTableNotFoundException(this.tableId);

  final String tableId;

  @override
  String toString() => 'Ruleset table not found: $tableId';
}

final class RulesetTableModuleInactiveException implements Exception {
  RulesetTableModuleInactiveException(this.tableId, this.moduleId);

  final String tableId;
  final String moduleId;

  @override
  String toString() =>
      'Ruleset table $tableId requires inactive module: $moduleId';
}

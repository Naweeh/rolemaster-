final class ResolutionRuleNotFoundException implements Exception {
  ResolutionRuleNotFoundException(this.ruleId);

  final String ruleId;

  @override
  String toString() => 'Resolution rule not found: $ruleId';
}

final class ResolutionInterpreterNotFoundException implements Exception {
  ResolutionInterpreterNotFoundException(this.kind);

  final String kind;

  @override
  String toString() => 'Resolution interpreter not found for kind: $kind';
}

final class DuplicateResolutionInterpreterException implements Exception {
  DuplicateResolutionInterpreterException(this.kind);

  final String kind;

  @override
  String toString() => 'Duplicate resolution interpreter kind: $kind';
}

final class ResolutionModuleInactiveException implements Exception {
  ResolutionModuleInactiveException(this.ruleId, this.moduleId);

  final String ruleId;
  final String moduleId;

  @override
  String toString() =>
      'Resolution rule $ruleId requires inactive module: $moduleId';
}

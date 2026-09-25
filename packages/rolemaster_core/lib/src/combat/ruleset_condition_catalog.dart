import '../ruleset/effective_ruleset.dart';

final class CombatCondition {
  CombatCondition({
    required String participantKey,
    required String conditionId,
    this.remainingRounds,
    String? sourceKey,
  })  : participantKey = participantKey.trim().toLowerCase(),
        conditionId = conditionId.trim(),
        sourceKey = sourceKey?.trim().toLowerCase() {
    if (this.participantKey.isEmpty ||
        this.conditionId.isEmpty ||
        remainingRounds != null && remainingRounds! < 1) {
      throw ArgumentError('Invalid combat condition or duration.');
    }
  }

  final String participantKey;
  final String conditionId;
  final int? remainingRounds;
  final String? sourceKey;

  String get key => '$participantKey:$conditionId';

  CombatCondition? afterRound() {
    if (remainingRounds == null) {
      return this;
    }
    if (remainingRounds == 1) {
      return null;
    }
    return CombatCondition(
      participantKey: participantKey,
      conditionId: conditionId,
      remainingRounds: remainingRounds! - 1,
      sourceKey: sourceKey,
    );
  }
}

final class ConditionDefinition {
  ConditionDefinition({
    required String id,
    String? moduleId,
    this.durationRounds,
    Map<String, int> statModifiers = const <String, int>{},
    Map<String, int> resolutionModifiers = const <String, int>{},
  })  : id = id.trim(),
        moduleId = moduleId?.trim(),
        statModifiers = Map<String, int>.unmodifiable(statModifiers),
        resolutionModifiers = Map<String, int>.unmodifiable(resolutionModifiers) {
    if (this.id.isEmpty ||
        this.moduleId != null && this.moduleId!.isEmpty ||
        durationRounds != null && durationRounds! < 1 ||
        this.statModifiers.keys.any((key) => key.trim().isEmpty) ||
        this.resolutionModifiers.keys.any((key) => key.trim().isEmpty)) {
      throw ArgumentError('Invalid condition ID, module, duration or modifier.');
    }
  }

  final String id;
  final String? moduleId;
  final int? durationRounds;
  final Map<String, int> statModifiers;
  final Map<String, int> resolutionModifiers;
}

final class RulesetConditionCatalog {
  RulesetConditionCatalog(this.ruleset);

  final EffectiveRuleset ruleset;

  List<ConditionDefinition> get definitions {
    final raw = ruleset.data['conditions'];
    if (raw == null) {
      return const <ConditionDefinition>[];
    }
    if (raw is! List) {
      throw StateError('conditions must be a list.');
    }
    final modules = ruleset.manifest.modules.map((item) => item.id).toSet();
    final seen = <String>{};
    final result = <ConditionDefinition>[];
    for (final value in raw) {
      if (value is! Map || value.keys.any((key) => key is! String)) {
        throw StateError('Condition definitions must be objects.');
      }
      final data = Map<String, Object?>.from(value);
      final id = data['id'];
      final moduleId = data['moduleId'];
      final duration = data['durationRounds'];
      if (id is! String ||
          moduleId != null &&
              (moduleId is! String || !modules.contains(moduleId.trim())) ||
          duration != null && duration is! int) {
        throw StateError('Invalid condition definition.');
      }
      final definition = ConditionDefinition(
        id: id,
        moduleId: moduleId as String?,
        durationRounds: duration as int?,
        statModifiers: _modifiers(data['statModifiers'], 'statModifiers'),
        resolutionModifiers:
            _modifiers(data['resolutionModifiers'], 'resolutionModifiers'),
      );
      if (!seen.add(definition.id)) {
        throw StateError('Duplicate condition ID: ${definition.id}.');
      }
      result.add(definition);
    }
    return List<ConditionDefinition>.unmodifiable(result);
  }

  ConditionDefinition requireActive(String id) {
    for (final definition in definitions) {
      if (definition.id == id.trim()) {
        if (definition.moduleId != null &&
            !ruleset.isModuleActive(definition.moduleId!)) {
          throw StateError('Condition requires an inactive module: $id.');
        }
        return definition;
      }
    }
    throw StateError('Condition not found: $id.');
  }
}

Map<String, int> _modifiers(Object? value, String field) {
  if (value == null) {
    return const <String, int>{};
  }
  if (value is! Map ||
      value.keys.any((key) => key is! String) ||
      value.values.any((item) => item is! int)) {
    throw StateError('Condition $field must contain integer values.');
  }
  return Map<String, int>.from(value);
}

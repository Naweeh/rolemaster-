final class RulesetModuleDefinition {
  RulesetModuleDefinition({
    required String id,
    required String name,
    this.required = false,
    this.enabledByDefault = false,
  })  : id = _normalizeRequired(id, 'id'),
        name = _normalizeRequired(name, 'name');

  final String id;
  final String name;
  final bool required;
  final bool enabledByDefault;
}

final class RulesetManifest {
  RulesetManifest({
    required String id,
    required String systemId,
    required String edition,
    required String version,
    required String displayName,
    Iterable<RulesetModuleDefinition> modules =
        const <RulesetModuleDefinition>[],
    Iterable<String> sourceReferences = const <String>[],
  })  : id = _normalizeRequired(id, 'id'),
        systemId = _normalizeRequired(systemId, 'systemId'),
        edition = _normalizeRequired(edition, 'edition'),
        version = _normalizeRequired(version, 'version'),
        displayName = _normalizeRequired(displayName, 'displayName'),
        modules = List<RulesetModuleDefinition>.unmodifiable(modules),
        sourceReferences = List<String>.unmodifiable(
          _normalizeUniqueStrings(sourceReferences),
        ) {
    final ids = <String>{};
    for (final module in this.modules) {
      if (!ids.add(module.id)) {
        throw ArgumentError.value(
          module.id,
          'modules',
          'Ruleset module ids must be unique.',
        );
      }
    }
  }

  final String id;
  final String systemId;
  final String edition;
  final String version;
  final String displayName;
  final List<RulesetModuleDefinition> modules;
  final List<String> sourceReferences;

  List<String> get requiredModuleIds => List<String>.unmodifiable(
        modules.where((module) => module.required).map((module) => module.id),
      );

  List<String> get defaultModuleIds => List<String>.unmodifiable(
        modules
            .where((module) => module.required || module.enabledByDefault)
            .map((module) => module.id),
      );
}

final class RulesetPackage {
  RulesetPackage({
    required this.manifest,
    Map<String, Object?> data = const <String, Object?>{},
  }) : data = _freezeMap(data);

  final RulesetManifest manifest;
  final Map<String, Object?> data;
}

final class CampaignRulesetBinding {
  CampaignRulesetBinding({
    required String campaignId,
    required String rulesetId,
    required String rulesetVersion,
    required Iterable<String> activeModuleIds,
    required DateTime boundAt,
  })  : campaignId = _normalizeRequired(campaignId, 'campaignId'),
        rulesetId = _normalizeRequired(rulesetId, 'rulesetId'),
        rulesetVersion = _normalizeRequired(rulesetVersion, 'rulesetVersion'),
        activeModuleIds = List<String>.unmodifiable(
          _normalizeUniqueStrings(activeModuleIds),
        ),
        boundAt = boundAt.toUtc();

  final String campaignId;
  final String rulesetId;
  final String rulesetVersion;
  final List<String> activeModuleIds;
  final DateTime boundAt;
}

final class CampaignRulesOverlay {
  CampaignRulesOverlay({
    required String campaignId,
    required DateTime updatedAt,
    Map<String, Object?> overrides = const <String, Object?>{},
  })  : campaignId = _normalizeRequired(campaignId, 'campaignId'),
        updatedAt = updatedAt.toUtc(),
        overrides = _freezeMap(overrides);

  factory CampaignRulesOverlay.clean({
    required String campaignId,
    required DateTime updatedAt,
  }) {
    return CampaignRulesOverlay(
      campaignId: campaignId,
      updatedAt: updatedAt,
    );
  }

  final String campaignId;
  final DateTime updatedAt;
  final Map<String, Object?> overrides;

  bool get isClean => overrides.isEmpty;

  CampaignRulesOverlay replaceOverrides(
    Map<String, Object?> values, {
    required DateTime at,
  }) {
    return CampaignRulesOverlay(
      campaignId: campaignId,
      updatedAt: at,
      overrides: values,
    );
  }
}

final class CampaignRulesetState {
  CampaignRulesetState({
    required this.binding,
    required this.overlay,
  }) {
    if (binding.campaignId != overlay.campaignId) {
      throw ArgumentError(
        'Ruleset binding and overlay must belong to the same campaign.',
      );
    }
  }

  final CampaignRulesetBinding binding;
  final CampaignRulesOverlay overlay;
}

String _normalizeRequired(String value, String fieldName) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, fieldName, '$fieldName cannot be empty.');
  }
  return normalized;
}

List<String> _normalizeUniqueStrings(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      continue;
    }
    if (seen.add(normalized)) {
      result.add(normalized);
    }
  }
  return result;
}

Map<String, Object?> _freezeMap(Map<String, Object?> source) {
  return Map<String, Object?>.unmodifiable(
    source.map((key, value) => MapEntry(key, _freezeJsonValue(value))),
  );
}

Object? _freezeJsonValue(Object? value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_freezeJsonValue));
  }
  if (value is Map) {
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw ArgumentError('Ruleset JSON object keys must be strings.');
      }
      result[entry.key as String] = _freezeJsonValue(entry.value);
    }
    return Map<String, Object?>.unmodifiable(result);
  }
  throw ArgumentError.value(
    value,
    'value',
    'Ruleset data must contain only JSON-compatible values.',
  );
}

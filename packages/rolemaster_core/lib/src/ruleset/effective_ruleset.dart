import 'ruleset_models.dart';

final class EffectiveRuleset {
  EffectiveRuleset({
    required String campaignId,
    required this.package,
    required Iterable<String> activeModuleIds,
    required CampaignRulesOverlay overlay,
  })  : campaignId = _required(campaignId, 'campaignId'),
        activeModuleIds = List<String>.unmodifiable(
          _normalizeUnique(activeModuleIds),
        ),
        data = _mergeMaps(package.data, overlay.overrides) {
    if (overlay.campaignId != this.campaignId) {
      throw ArgumentError(
        'Effective ruleset overlay must belong to campaign $campaignId.',
      );
    }
  }

  final String campaignId;
  final RulesetPackage package;
  final List<String> activeModuleIds;
  final Map<String, Object?> data;

  RulesetManifest get manifest => package.manifest;

  String get rulesetId => manifest.id;

  String get version => manifest.version;

  bool isModuleActive(String moduleId) {
    return activeModuleIds.contains(moduleId.trim());
  }

  Object? value(String key) => data[key.trim()];
}

Map<String, Object?> _mergeMaps(
  Map<String, Object?> base,
  Map<String, Object?> overrides,
) {
  final merged = <String, Object?>{};
  for (final entry in base.entries) {
    merged[entry.key] = _freeze(entry.value);
  }
  for (final entry in overrides.entries) {
    final existing = merged[entry.key];
    final override = entry.value;
    if (existing is Map && override is Map) {
      merged[entry.key] = _mergeMaps(
        _stringMap(existing),
        _stringMap(override),
      );
    } else {
      merged[entry.key] = _freeze(override);
    }
  }
  return Map<String, Object?>.unmodifiable(merged);
}

Map<String, Object?> _stringMap(Map value) {
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw ArgumentError('Effective ruleset map keys must be strings.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

Object? _freeze(Object? value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_freeze));
  }
  if (value is Map) {
    return Map<String, Object?>.unmodifiable(
      _stringMap(value).map((key, item) => MapEntry(key, _freeze(item))),
    );
  }
  throw ArgumentError.value(
    value,
    'value',
    'Effective ruleset data must be JSON-compatible.',
  );
}

List<String> _normalizeUnique(Iterable<String> values) {
  final result = <String>[];
  final seen = <String>{};
  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isNotEmpty && seen.add(normalized)) {
      result.add(normalized);
    }
  }
  return result;
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, '$field cannot be empty.');
  }
  return normalized;
}

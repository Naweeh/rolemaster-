import 'package:rolemaster_core/rolemaster_core.dart';

final class InMemoryRulesetRepository
    implements RulesetRepository, RulesetPublisher {
  InMemoryRulesetRepository([
    Iterable<RulesetPackage> initial = const <RulesetPackage>[],
  ]) {
    for (final package in initial) {
      _packages[_key(package.manifest.id, package.manifest.version)] = package;
    }
  }

  final Map<String, RulesetPackage> _packages = <String, RulesetPackage>{};

  @override
  Future<void> publish(RulesetPackage package) async {
    final key = _key(package.manifest.id, package.manifest.version);
    if (_packages.containsKey(key)) {
      throw StateError('Ruleset package $key is already published.');
    }
    _packages[key] = package;
  }

  @override
  Future<RulesetPackage?> getPackage({
    required String rulesetId,
    required String version,
  }) async {
    return _packages[_key(rulesetId, version)];
  }

  @override
  Future<List<RulesetPackage>> getAvailablePackages() async {
    final packages = _packages.values.toList(growable: false)
      ..sort((a, b) {
        final system = a.manifest.systemId.compareTo(b.manifest.systemId);
        if (system != 0) return system;
        final edition = a.manifest.edition.compareTo(b.manifest.edition);
        if (edition != 0) return edition;
        return a.manifest.version.compareTo(b.manifest.version);
      });
    return packages;
  }

  String _key(String id, String version) => '$id@$version';
}

final class InMemoryCampaignRulesetRepository
    implements CampaignRulesetRepository {
  final Map<String, CampaignRulesetState> _states =
      <String, CampaignRulesetState>{};

  @override
  Future<CampaignRulesetState?> getForCampaign(String campaignId) async {
    return _states[campaignId.trim()];
  }

  @override
  Future<void> migrate({
    required CampaignRulesetState expected,
    required CampaignRulesetState next,
  }) async {
    final current = _states[expected.campaignId];
    if (current == null ||
        current.binding.rulesetId != expected.rulesetId ||
        current.binding.rulesetVersion != expected.rulesetVersion ||
        current.binding.boundAt != expected.boundAt) {
      throw StateError('Campaign ruleset changed during migration.');
    }
    _states[expected.campaignId] = next;
  }

  @override
  Future<void> save(CampaignRulesetState state) async {
    final current = _states[state.binding.campaignId];
    if (current != null &&
        (current.binding.rulesetId != state.binding.rulesetId ||
            current.binding.rulesetVersion != state.binding.rulesetVersion)) {
      throw StateError(
        'Changing a campaign ruleset requires a controlled migration.',
      );
    }
    _states[state.binding.campaignId] = state;
  }
}

final class RulesetNotFoundException implements Exception {
  RulesetNotFoundException(this.rulesetId, this.version);

  final String rulesetId;
  final String version;

  @override
  String toString() => 'Ruleset not found: $rulesetId@$version';
}

final class CampaignRulesetAlreadyInitializedException implements Exception {
  CampaignRulesetAlreadyInitializedException(this.campaignId);

  final String campaignId;

  @override
  String toString() => 'Campaign ruleset already initialized: $campaignId';
}

final class CampaignRulesetNotInitializedException implements Exception {
  CampaignRulesetNotInitializedException(this.campaignId);

  final String campaignId;

  @override
  String toString() => 'Campaign ruleset not initialized: $campaignId';
}

final class UnknownRulesetModuleException implements Exception {
  UnknownRulesetModuleException(this.moduleId);

  final String moduleId;

  @override
  String toString() => 'Unknown ruleset module: $moduleId';
}

final class RequiredRulesetModuleMissingException implements Exception {
  RequiredRulesetModuleMissingException(this.moduleId);

  final String moduleId;

  @override
  String toString() => 'Required ruleset module missing: $moduleId';
}

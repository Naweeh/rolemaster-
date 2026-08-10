import '../character/character_exceptions.dart';
import '../character/character_repository.dart';
import '../ruleset/ruleset_exceptions.dart';
import '../ruleset/ruleset_repository.dart';
import 'character_skill_repository.dart';
import 'character_skill_state.dart';
import 'ruleset_skill_catalog.dart';
import 'skill_exceptions.dart';

typedef SkillClock = DateTime Function();

final class SetCharacterSkill {
  SetCharacterSkill({
    required CharacterRepository characterRepository,
    required RulesetRepository rulesetRepository,
    required CampaignRulesetRepository campaignRulesetRepository,
    required CharacterSkillRepository characterSkillRepository,
    required SkillClock clock,
  })  : _characterRepository = characterRepository,
        _rulesetRepository = rulesetRepository,
        _campaignRulesetRepository = campaignRulesetRepository,
        _characterSkillRepository = characterSkillRepository,
        _clock = clock;

  final CharacterRepository _characterRepository;
  final RulesetRepository _rulesetRepository;
  final CampaignRulesetRepository _campaignRulesetRepository;
  final CharacterSkillRepository _characterSkillRepository;
  final SkillClock _clock;

  Future<CharacterSkillState> call({
    required String characterId,
    required String skillId,
    required int ranks,
    Map<String, int> modifiers = const <String, int>{},
    String? notes,
  }) async {
    final character = await _characterRepository.getById(characterId);
    if (character == null) {
      throw CharacterNotFoundException(characterId);
    }
    if (character.isArchived) {
      throw ArchivedCharacterSkillChangeException(character.id);
    }

    final campaignRuleset =
        await _campaignRulesetRepository.getForCampaign(character.campaignId);
    if (campaignRuleset == null) {
      throw CampaignRulesetNotInitializedException(character.campaignId);
    }

    final package = await _rulesetRepository.getPackage(
      rulesetId: campaignRuleset.binding.rulesetId,
      version: campaignRuleset.binding.rulesetVersion,
    );
    if (package == null) {
      throw RulesetNotFoundException(
        campaignRuleset.binding.rulesetId,
        campaignRuleset.binding.rulesetVersion,
      );
    }

    final catalog = RulesetSkillCatalog.fromPackage(package);
    final definition = catalog.getById(skillId);
    if (definition == null) {
      throw SkillDefinitionNotFoundException(skillId);
    }
    final moduleId = definition.moduleId;
    if (moduleId != null &&
        !campaignRuleset.binding.activeModuleIds.contains(moduleId)) {
      throw SkillModuleInactiveException(definition.id, moduleId);
    }

    final state = CharacterSkillState(
      characterId: character.id,
      skillId: definition.id,
      ranks: ranks,
      modifiers: modifiers,
      notes: notes,
      updatedAt: _clock(),
    );
    await _characterSkillRepository.save(state);
    return state;
  }
}

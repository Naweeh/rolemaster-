import '../character/character_exceptions.dart';
import '../character/character_repository.dart';
import '../ruleset/ruleset_exceptions.dart';
import '../ruleset/ruleset_repository.dart';
import 'character_skill_repository.dart';
import 'character_skill_state.dart';
import 'ruleset_skill_catalog.dart';
import 'skill_definition.dart';

final class CharacterSkillEntry {
  const CharacterSkillEntry({
    required this.definition,
    required this.state,
  });

  final SkillDefinition definition;
  final CharacterSkillState? state;
}

final class ListCharacterSkills {
  ListCharacterSkills({
    required CharacterRepository characterRepository,
    required RulesetRepository rulesetRepository,
    required CampaignRulesetRepository campaignRulesetRepository,
    required CharacterSkillRepository characterSkillRepository,
  })  : _characterRepository = characterRepository,
        _rulesetRepository = rulesetRepository,
        _campaignRulesetRepository = campaignRulesetRepository,
        _characterSkillRepository = characterSkillRepository;

  final CharacterRepository _characterRepository;
  final RulesetRepository _rulesetRepository;
  final CampaignRulesetRepository _campaignRulesetRepository;
  final CharacterSkillRepository _characterSkillRepository;

  Future<List<CharacterSkillEntry>> call(String characterId) async {
    final character = await _characterRepository.getById(characterId);
    if (character == null) {
      throw CharacterNotFoundException(characterId);
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
    final available = catalog.availableForModules(
      campaignRuleset.binding.activeModuleIds,
    );
    final states =
        await _characterSkillRepository.getForCharacter(character.id);
    final stateBySkill = <String, CharacterSkillState>{
      for (final state in states) state.skillId: state,
    };

    return List<CharacterSkillEntry>.unmodifiable(
      available.map(
        (definition) => CharacterSkillEntry(
          definition: definition,
          state: stateBySkill[definition.id],
        ),
      ),
    );
  }
}

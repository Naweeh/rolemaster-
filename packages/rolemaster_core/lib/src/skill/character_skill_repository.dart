import 'character_skill_state.dart';

abstract interface class CharacterSkillRepository {
  Future<CharacterSkillState?> getByCharacterAndSkill({
    required String characterId,
    required String skillId,
  });

  Future<List<CharacterSkillState>> getForCharacter(String characterId);

  Future<void> save(CharacterSkillState state);
}

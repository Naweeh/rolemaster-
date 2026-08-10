import 'package:rolemaster_core/rolemaster_core.dart';

final class InMemoryCharacterRepository implements CharacterRepository {
  final List<Character> _characters = <Character>[];

  @override
  Future<Character?> getById(String id) async {
    for (final character in _characters) {
      if (character.id == id) {
        return character;
      }
    }
    return null;
  }

  @override
  Future<List<Character>> getForCampaign(
    String campaignId, {
    bool includeArchived = false,
  }) async {
    final characters = _characters.where(
      (character) =>
          character.campaignId == campaignId &&
          (includeArchived || !character.isArchived),
    );
    return List<Character>.unmodifiable(characters);
  }

  @override
  Future<void> save(Character character) async {
    final index = _characters.indexWhere((item) => item.id == character.id);
    if (index >= 0) {
      _characters[index] = character;
      return;
    }
    _characters.add(character);
  }
}

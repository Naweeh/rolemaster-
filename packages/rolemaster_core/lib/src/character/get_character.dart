import 'character.dart';
import 'character_exceptions.dart';
import 'character_repository.dart';

final class GetCharacter {
  GetCharacter({required CharacterRepository repository})
      : _repository = repository;

  final CharacterRepository _repository;

  Future<Character> call(String characterId) async {
    final normalizedId = characterId.trim();
    final character = await _repository.getById(normalizedId);
    if (character == null) {
      throw CharacterNotFoundException(normalizedId);
    }
    return character;
  }
}

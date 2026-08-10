import 'character.dart';
import 'character_exceptions.dart';
import 'character_repository.dart';
import 'character_support.dart';

final class ArchiveCharacter {
  ArchiveCharacter({
    required CharacterRepository repository,
    required CharacterClock clock,
  })  : _repository = repository,
        _clock = clock;

  final CharacterRepository _repository;
  final CharacterClock _clock;

  Future<Character> call(String characterId) async {
    final normalizedId = characterId.trim();
    final existing = await _repository.getById(normalizedId);
    if (existing == null) {
      throw CharacterNotFoundException(normalizedId);
    }

    final archived = existing.archive(at: _clock());
    await _repository.save(archived);
    return archived;
  }
}

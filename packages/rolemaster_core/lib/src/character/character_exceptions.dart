final class CharacterNotFoundException implements Exception {
  CharacterNotFoundException(this.characterId);

  final String characterId;

  @override
  String toString() => 'Character not found: $characterId';
}

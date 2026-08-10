final class VisualAlphaCharacterProfile {
  VisualAlphaCharacterProfile({
    required String characterId,
    required String rulesetId,
    required String rulesetVersion,
    required String className,
    required String alignment,
    required Map<String, int> abilities,
    required int startingGold,
  })  : characterId = characterId.trim(),
        rulesetId = rulesetId.trim(),
        rulesetVersion = rulesetVersion.trim(),
        className = className.trim(),
        alignment = alignment.trim(),
        abilities = Map<String, int>.unmodifiable(abilities),
        startingGold = startingGold {
    if (this.characterId.isEmpty ||
        this.rulesetId.isEmpty ||
        this.rulesetVersion.isEmpty ||
        this.className.isEmpty ||
        this.alignment.isEmpty) {
      throw ArgumentError('Visual alpha character profile fields cannot be empty.');
    }
    if (this.abilities.isEmpty) {
      throw ArgumentError('Visual alpha character abilities cannot be empty.');
    }
    if (startingGold < 0) {
      throw ArgumentError.value(startingGold, 'startingGold');
    }
  }

  final String characterId;
  final String rulesetId;
  final String rulesetVersion;
  final String className;
  final String alignment;
  final Map<String, int> abilities;
  final int startingGold;
}

abstract interface class VisualAlphaCharacterProfileRepository {
  Future<VisualAlphaCharacterProfile?> getForCharacter(String characterId);

  Future<void> save(VisualAlphaCharacterProfile profile);
}

final class InMemoryVisualAlphaCharacterProfileRepository
    implements VisualAlphaCharacterProfileRepository {
  final Map<String, VisualAlphaCharacterProfile> _profiles =
      <String, VisualAlphaCharacterProfile>{};

  @override
  Future<VisualAlphaCharacterProfile?> getForCharacter(String characterId) async {
    return _profiles[characterId];
  }

  @override
  Future<void> save(VisualAlphaCharacterProfile profile) async {
    _profiles[profile.characterId] = profile;
  }
}

final class CreatureNotFoundException implements Exception {
  CreatureNotFoundException(this.creatureId);

  final String creatureId;

  @override
  String toString() => 'Creature not found: $creatureId';
}

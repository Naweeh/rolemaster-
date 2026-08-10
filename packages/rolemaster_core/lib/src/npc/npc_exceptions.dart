final class NpcNotFoundException implements Exception {
  NpcNotFoundException(this.npcId);

  final String npcId;

  @override
  String toString() => 'NPC not found: $npcId';
}

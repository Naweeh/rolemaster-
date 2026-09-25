import '../character/character_repository.dart';
import '../creature/creature_repository.dart';
import '../encounter/encounter.dart';
import '../npc/npc_repository.dart';

final class CombatParticipant {
  CombatParticipant({
    required String entityType,
    required String entityId,
    required String name,
  })  : entityType = entityType.trim().toLowerCase(),
        entityId = entityId.trim(),
        name = name.trim() {
    if (this.entityId.isEmpty || this.name.isEmpty) {
      throw ArgumentError('Combat participant ID and name are required.');
    }
    if (!const <String>{'character', 'npc', 'creature'}
        .contains(this.entityType)) {
      throw ArgumentError('Unsupported combat participant type: $entityType.');
    }
  }

  final String entityType;
  final String entityId;
  final String name;

  String get key => '$entityType:$entityId';
}

final class CombatParticipantResolver {
  CombatParticipantResolver({
    required CharacterRepository characters,
    required NpcRepository npcs,
    required CreatureRepository creatures,
  })  : _characters = characters,
        _npcs = npcs,
        _creatures = creatures;

  final CharacterRepository _characters;
  final NpcRepository _npcs;
  final CreatureRepository _creatures;

  Future<List<CombatParticipant>> resolve(Encounter encounter) async {
    final participants = <CombatParticipant>[];
    for (final reference in encounter.participants) {
      final type = reference.entityType.toLowerCase();
      final id = reference.entityId;
      String? name;
      String? campaignId;
      bool? archived;
      switch (type) {
        case 'character':
          final entity = await _characters.getById(id);
          name = entity?.name;
          campaignId = entity?.campaignId;
          archived = entity?.isArchived;
        case 'npc':
          final entity = await _npcs.getById(id);
          name = entity?.name;
          campaignId = entity?.campaignId;
          archived = entity?.isArchived;
        case 'creature':
          final entity = await _creatures.getById(id);
          name = entity?.name;
          campaignId = entity?.campaignId;
          archived = entity?.isArchived;
        default:
          throw StateError('Unsupported combat participant type: $type.');
      }
      if (name == null || campaignId != encounter.campaignId || archived == true) {
        throw StateError('Combat participant unavailable: $type:$id.');
      }
      participants.add(
        CombatParticipant(entityType: type, entityId: id, name: name),
      );
    }
    return List<CombatParticipant>.unmodifiable(participants);
  }
}

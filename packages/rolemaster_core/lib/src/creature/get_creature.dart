import 'creature.dart';
import 'creature_exceptions.dart';
import 'creature_repository.dart';

final class GetCreature {
  GetCreature({required CreatureRepository repository})
      : _repository = repository;

  final CreatureRepository _repository;

  Future<Creature> call(String creatureId) async {
    final normalizedId = creatureId.trim();
    final creature = await _repository.getById(normalizedId);
    if (creature == null) {
      throw CreatureNotFoundException(normalizedId);
    }
    return creature;
  }
}

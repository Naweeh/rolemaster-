import 'creature.dart';
import 'creature_exceptions.dart';
import 'creature_repository.dart';
import 'creature_support.dart';

final class ArchiveCreature {
  ArchiveCreature({
    required CreatureRepository repository,
    required CreatureClock clock,
  })  : _repository = repository,
        _clock = clock;

  final CreatureRepository _repository;
  final CreatureClock _clock;

  Future<Creature> call(String creatureId) async {
    final normalizedId = creatureId.trim();
    final existing = await _repository.getById(normalizedId);
    if (existing == null) {
      throw CreatureNotFoundException(normalizedId);
    }

    final archived = existing.archive(at: _clock());
    await _repository.save(archived);
    return archived;
  }
}

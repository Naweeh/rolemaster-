import '../world/world_repository.dart';
import 'creature.dart';
import 'creature_exceptions.dart';
import 'creature_metadata.dart';
import 'creature_placement.dart';
import 'creature_placement_validator.dart';
import 'creature_repository.dart';
import 'creature_support.dart';

final class UpdateCreature {
  UpdateCreature({
    required CreatureRepository repository,
    required WorldRepository worldRepository,
    required CreatureClock clock,
  })  : _repository = repository,
        _worldRepository = worldRepository,
        _clock = clock;

  final CreatureRepository _repository;
  final WorldRepository _worldRepository;
  final CreatureClock _clock;

  Future<Creature> call(
    String creatureId, {
    String? name,
    CreatureMetadata? metadata,
    CreaturePlacement? placement,
  }) async {
    final normalizedId = creatureId.trim();
    final existing = await _repository.getById(normalizedId);
    if (existing == null) {
      throw CreatureNotFoundException(normalizedId);
    }

    if (placement != null) {
      await validateCreaturePlacement(
        placement: placement,
        campaignId: existing.campaignId,
        worldRepository: _worldRepository,
      );
    }

    final updated = existing.update(
      name: name,
      metadata: metadata,
      placement: placement,
      at: _clock(),
    );
    await _repository.save(updated);
    return updated;
  }
}

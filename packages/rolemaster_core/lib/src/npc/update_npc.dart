import '../world/world_repository.dart';
import 'npc.dart';
import 'npc_exceptions.dart';
import 'npc_metadata.dart';
import 'npc_placement.dart';
import 'npc_placement_validator.dart';
import 'npc_repository.dart';
import 'npc_support.dart';

final class UpdateNpc {
  UpdateNpc({
    required NpcRepository repository,
    required WorldRepository worldRepository,
    required NpcClock clock,
  })  : _repository = repository,
        _worldRepository = worldRepository,
        _clock = clock;

  final NpcRepository _repository;
  final WorldRepository _worldRepository;
  final NpcClock _clock;

  Future<Npc> call(
    String npcId, {
    String? name,
    NpcMetadata? metadata,
    NpcPlacement? placement,
  }) async {
    final normalizedId = npcId.trim();
    final existing = await _repository.getById(normalizedId);
    if (existing == null) {
      throw NpcNotFoundException(normalizedId);
    }

    if (placement != null) {
      await validateNpcPlacement(
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

import 'npc.dart';
import 'npc_exceptions.dart';
import 'npc_repository.dart';
import 'npc_support.dart';

final class ArchiveNpc {
  ArchiveNpc({
    required NpcRepository repository,
    required NpcClock clock,
  })  : _repository = repository,
        _clock = clock;

  final NpcRepository _repository;
  final NpcClock _clock;

  Future<Npc> call(String npcId) async {
    final normalizedId = npcId.trim();
    final existing = await _repository.getById(normalizedId);
    if (existing == null) {
      throw NpcNotFoundException(normalizedId);
    }

    final archived = existing.archive(at: _clock());
    await _repository.save(archived);
    return archived;
  }
}

import 'npc.dart';
import 'npc_exceptions.dart';
import 'npc_repository.dart';

final class GetNpc {
  GetNpc({required NpcRepository repository}) : _repository = repository;

  final NpcRepository _repository;

  Future<Npc> call(String npcId) async {
    final normalizedId = npcId.trim();
    final npc = await _repository.getById(normalizedId);
    if (npc == null) {
      throw NpcNotFoundException(normalizedId);
    }
    return npc;
  }
}

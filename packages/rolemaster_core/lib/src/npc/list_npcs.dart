import 'npc.dart';
import 'npc_repository.dart';

final class ListNpcs {
  ListNpcs({required NpcRepository repository}) : _repository = repository;

  final NpcRepository _repository;

  Future<List<Npc>> call(
    String campaignId, {
    bool includeArchived = false,
  }) {
    return _repository.getForCampaign(
      campaignId.trim(),
      includeArchived: includeArchived,
    );
  }
}

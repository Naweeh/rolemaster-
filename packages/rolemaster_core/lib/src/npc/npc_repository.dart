import 'npc.dart';

abstract interface class NpcRepository {
  Future<Npc?> getById(String id);

  Future<List<Npc>> getForCampaign(
    String campaignId, {
    bool includeArchived = false,
  });

  Future<void> save(Npc npc);
}

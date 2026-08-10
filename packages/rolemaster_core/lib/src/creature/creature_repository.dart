import 'creature.dart';

abstract interface class CreatureRepository {
  Future<Creature?> getById(String id);

  Future<List<Creature>> getForCampaign(
    String campaignId, {
    bool includeArchived = false,
  });

  Future<void> save(Creature creature);
}

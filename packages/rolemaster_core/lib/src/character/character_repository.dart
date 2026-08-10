import 'character.dart';

abstract interface class CharacterRepository {
  Future<Character?> getById(String id);

  Future<List<Character>> getForCampaign(
    String campaignId, {
    bool includeArchived = false,
  });

  Future<void> save(Character character);
}

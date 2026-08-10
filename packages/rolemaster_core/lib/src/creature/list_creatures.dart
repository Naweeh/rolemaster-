import 'creature.dart';
import 'creature_repository.dart';

final class ListCreatures {
  ListCreatures({required CreatureRepository repository})
      : _repository = repository;

  final CreatureRepository _repository;

  Future<List<Creature>> call(
    String campaignId, {
    bool includeArchived = false,
  }) {
    return _repository.getForCampaign(
      campaignId.trim(),
      includeArchived: includeArchived,
    );
  }
}

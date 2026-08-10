import 'character.dart';
import 'character_repository.dart';

final class ListCharacters {
  ListCharacters({required CharacterRepository repository})
      : _repository = repository;

  final CharacterRepository _repository;

  Future<List<Character>> call(
    String campaignId, {
    bool includeArchived = false,
  }) {
    return _repository.getForCampaign(
      campaignId.trim(),
      includeArchived: includeArchived,
    );
  }
}

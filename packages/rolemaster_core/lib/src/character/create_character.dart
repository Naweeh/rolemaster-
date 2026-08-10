import '../campaign/campaign_not_found_exception.dart';
import '../campaign/campaign_repository.dart';
import 'character.dart';
import 'character_metadata.dart';
import 'character_repository.dart';
import 'character_support.dart';

final class CreateCharacter {
  CreateCharacter({
    required CharacterRepository repository,
    required CampaignRepository campaignRepository,
    required CharacterIdGenerator idGenerator,
    required CharacterClock clock,
  })  : _repository = repository,
        _campaignRepository = campaignRepository,
        _idGenerator = idGenerator,
        _clock = clock;

  final CharacterRepository _repository;
  final CampaignRepository _campaignRepository;
  final CharacterIdGenerator _idGenerator;
  final CharacterClock _clock;

  Future<Character> call({
    required String campaignId,
    required String name,
    CharacterMetadata? metadata,
  }) async {
    final normalizedCampaignId = campaignId.trim();
    if (normalizedCampaignId.isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'Character campaignId cannot be empty.',
      );
    }

    final campaign = await _campaignRepository.getById(normalizedCampaignId);
    if (campaign == null) {
      throw CampaignNotFoundException(normalizedCampaignId);
    }
    if (campaign.isArchived) {
      throw StateError('Cannot create characters in an archived campaign.');
    }

    final now = _clock().toUtc();
    final character = Character(
      id: _idGenerator(),
      campaignId: normalizedCampaignId,
      name: name,
      createdAt: now,
      updatedAt: now,
      metadata: metadata,
    );
    await _repository.save(character);
    return character;
  }
}

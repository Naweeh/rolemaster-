import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  group('Character use cases', () {
    test('creates a character only inside an active campaign', () async {
      final campaigns = _MemoryCampaignRepository(<Campaign>[
        Campaign(
          id: 'campaign-1',
          name: 'Campaña',
          createdAt: DateTime.utc(2026, 8, 10, 10),
        ),
      ]);
      final characters = _MemoryCharacterRepository();
      final create = CreateCharacter(
        repository: characters,
        campaignRepository: campaigns,
        idGenerator: () => 'character-1',
        clock: () => DateTime.utc(2026, 8, 10, 12),
      );

      final character = await create(
        campaignId: 'campaign-1',
        name: 'Aria',
        metadata: CharacterMetadata(playerName: 'Alex'),
      );

      expect(character.id, 'character-1');
      expect(character.campaignId, 'campaign-1');
      expect(character.metadata.playerName, 'Alex');
      expect(await characters.getById('character-1'), same(character));
    });

    test('rejects missing and archived campaigns', () async {
      final archived = Campaign(
        id: 'campaign-archived',
        name: 'Archivada',
        createdAt: DateTime.utc(2026, 8, 10, 9),
      ).archive(at: DateTime.utc(2026, 8, 10, 10));
      final campaigns = _MemoryCampaignRepository(<Campaign>[archived]);
      final characters = _MemoryCharacterRepository();
      final create = CreateCharacter(
        repository: characters,
        campaignRepository: campaigns,
        idGenerator: () => 'character-1',
        clock: () => DateTime.utc(2026, 8, 10, 12),
      );

      await expectLater(
        create(campaignId: 'missing', name: 'Aria'),
        throwsA(isA<CampaignNotFoundException>()),
      );
      await expectLater(
        create(campaignId: 'campaign-archived', name: 'Aria'),
        throwsStateError,
      );
      expect(await characters.getForCampaign('campaign-archived'), isEmpty);
    });

    test('gets, updates, archives and filters characters', () async {
      final repository = _MemoryCharacterRepository(<Character>[
        Character(
          id: 'character-1',
          campaignId: 'campaign-1',
          name: 'Aria',
          createdAt: DateTime.utc(2026, 8, 10, 10),
        ),
        Character(
          id: 'character-2',
          campaignId: 'campaign-2',
          name: 'Otro',
          createdAt: DateTime.utc(2026, 8, 10, 10),
        ),
      ]);
      final get = GetCharacter(repository: repository);
      final update = UpdateCharacter(
        repository: repository,
        clock: () => DateTime.utc(2026, 8, 10, 11),
      );
      final archive = ArchiveCharacter(
        repository: repository,
        clock: () => DateTime.utc(2026, 8, 10, 12),
      );
      final list = ListCharacters(repository: repository);

      expect((await get('character-1')).name, 'Aria');
      final updated = await update(
        'character-1',
        name: 'Aria Renombrada',
        metadata: CharacterMetadata(notes: 'Actualizada'),
      );
      expect(updated.name, 'Aria Renombrada');
      expect(updated.metadata.notes, 'Actualizada');

      await archive('character-1');
      expect(await list('campaign-1'), isEmpty);
      expect(await list('campaign-1', includeArchived: true), hasLength(1));
      expect(await list('campaign-2'), hasLength(1));
    });

    test('reports missing characters for get, update and archive', () async {
      final repository = _MemoryCharacterRepository();

      await expectLater(
        GetCharacter(repository: repository)('missing'),
        throwsA(isA<CharacterNotFoundException>()),
      );
      await expectLater(
        UpdateCharacter(
          repository: repository,
          clock: DateTime.now,
        )('missing', name: 'No existe'),
        throwsA(isA<CharacterNotFoundException>()),
      );
      await expectLater(
        ArchiveCharacter(
          repository: repository,
          clock: DateTime.now,
        )('missing'),
        throwsA(isA<CharacterNotFoundException>()),
      );
    });
  });
}

final class _MemoryCharacterRepository implements CharacterRepository {
  _MemoryCharacterRepository([
    Iterable<Character> initial = const <Character>[],
  ]) {
    for (final character in initial) {
      _characters[character.id] = character;
    }
  }

  final Map<String, Character> _characters = <String, Character>{};

  @override
  Future<Character?> getById(String id) async => _characters[id];

  @override
  Future<List<Character>> getForCampaign(
    String campaignId, {
    bool includeArchived = false,
  }) async {
    return _characters.values
        .where(
          (character) =>
              character.campaignId == campaignId &&
              (includeArchived || !character.isArchived),
        )
        .toList(growable: false);
  }

  @override
  Future<void> save(Character character) async {
    _characters[character.id] = character;
  }
}

final class _MemoryCampaignRepository implements CampaignRepository {
  _MemoryCampaignRepository(Iterable<Campaign> initial) {
    for (final campaign in initial) {
      _campaigns[campaign.id] = campaign;
    }
  }

  final Map<String, Campaign> _campaigns = <String, Campaign>{};

  @override
  Future<List<Campaign>> getAll({bool includeArchived = false}) async {
    return _campaigns.values
        .where((campaign) => includeArchived || !campaign.isArchived)
        .toList(growable: false);
  }

  @override
  Future<Campaign?> getById(String id) async => _campaigns[id];

  @override
  Future<void> save(Campaign campaign) async {
    _campaigns[campaign.id] = campaign;
  }
}

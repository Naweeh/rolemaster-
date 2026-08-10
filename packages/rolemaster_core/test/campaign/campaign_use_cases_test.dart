import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  group('Campaign use cases', () {
    test('GetCampaign returns campaign by id', () async {
      final repository = _MemoryCampaignRepository(<Campaign>[
        _campaign(id: 'campaign-1', name: 'Uno'),
      ]);
      final useCase = GetCampaign(repository: repository);

      final campaign = await useCase(' campaign-1 ');

      expect(campaign.name, 'Uno');
    });

    test('GetCampaign throws when campaign does not exist', () async {
      final repository = _MemoryCampaignRepository();
      final useCase = GetCampaign(repository: repository);

      await expectLater(
        useCase('missing'),
        throwsA(isA<CampaignNotFoundException>()),
      );
    });

    test('ListCampaigns hides archived campaigns by default', () async {
      final active = _campaign(id: 'active', name: 'Activa');
      final archived = _campaign(id: 'archived', name: 'Archivada').archive(
        at: DateTime.utc(2026, 8, 10, 12),
      );
      final repository =
          _MemoryCampaignRepository(<Campaign>[active, archived]);
      final useCase = ListCampaigns(repository: repository);

      final visible = await useCase();
      final all = await useCase(includeArchived: true);

      expect(visible.map((campaign) => campaign.id), <String>['active']);
      expect(all, hasLength(2));
    });

    test('RenameCampaign persists renamed campaign', () async {
      final repository = _MemoryCampaignRepository(<Campaign>[
        _campaign(id: 'campaign-1', name: 'Original'),
      ]);
      final useCase = RenameCampaign(
        repository: repository,
        clock: () => DateTime.utc(2026, 8, 10, 13),
      );

      final renamed = await useCase(id: 'campaign-1', name: 'Nueva');

      expect(renamed.name, 'Nueva');
      expect((await repository.getById('campaign-1'))?.name, 'Nueva');
    });

    test('UpdateCampaign persists metadata and configuration', () async {
      final repository = _MemoryCampaignRepository(<Campaign>[
        _campaign(id: 'campaign-1', name: 'Original'),
      ]);
      final useCase = UpdateCampaign(
        repository: repository,
        clock: () => DateTime.utc(2026, 8, 10, 14),
      );
      final metadata = CampaignMetadata(
        description: 'Campaña de prueba',
        tags: <String>['principal', 'presencial'],
      );
      const configuration = CampaignConfiguration(
        aiEnabled: false,
        voiceEnabled: true,
        audioEnabled: false,
      );

      final updated = await useCase(
        id: ' campaign-1 ',
        metadata: metadata,
        configuration: configuration,
      );

      expect(updated.metadata.description, 'Campaña de prueba');
      expect(updated.metadata.tags, <String>['principal', 'presencial']);
      expect(updated.configuration.aiEnabled, isFalse);
      expect(updated.configuration.voiceEnabled, isTrue);
      expect(updated.configuration.audioEnabled, isFalse);

      final persisted = await repository.getById('campaign-1');
      expect(persisted?.metadata.description, 'Campaña de prueba');
      expect(persisted?.configuration.aiEnabled, isFalse);
    });

    test('UpdateCampaign throws when campaign does not exist', () async {
      final repository = _MemoryCampaignRepository();
      final useCase = UpdateCampaign(
        repository: repository,
        clock: () => DateTime.utc(2026, 8, 10, 14),
      );

      await expectLater(
        useCase(id: 'missing', name: 'Nueva'),
        throwsA(isA<CampaignNotFoundException>()),
      );
    });

    test('ArchiveCampaign persists archived state', () async {
      final repository = _MemoryCampaignRepository(<Campaign>[
        _campaign(id: 'campaign-1', name: 'Campaign'),
      ]);
      final useCase = ArchiveCampaign(
        repository: repository,
        clock: () => DateTime.utc(2026, 8, 10, 13),
      );

      final archived = await useCase('campaign-1');

      expect(archived.isArchived, isTrue);
      expect((await repository.getById('campaign-1'))?.isArchived, isTrue);
    });
  });
}

Campaign _campaign({required String id, required String name}) {
  return Campaign(
    id: id,
    name: name,
    createdAt: DateTime.utc(2026, 8, 10, 10),
  );
}

final class _MemoryCampaignRepository implements CampaignRepository {
  _MemoryCampaignRepository([List<Campaign>? campaigns]) {
    for (final campaign in campaigns ?? const <Campaign>[]) {
      _campaigns[campaign.id] = campaign;
    }
  }

  final Map<String, Campaign> _campaigns = <String, Campaign>{};

  @override
  Future<Campaign?> getById(String id) async => _campaigns[id];

  @override
  Future<List<Campaign>> getAll({bool includeArchived = false}) async {
    return _campaigns.values
        .where((campaign) => includeArchived || !campaign.isArchived)
        .toList(growable: false);
  }

  @override
  Future<void> save(Campaign campaign) async {
    _campaigns[campaign.id] = campaign;
  }
}

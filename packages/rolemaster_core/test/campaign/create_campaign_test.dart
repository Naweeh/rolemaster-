import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  group('CreateCampaign', () {
    test('generates id, normalizes time to UTC and saves through repository', () async {
      final repository = _RecordingCampaignRepository();
      final localTime = DateTime(2026, 8, 10, 11, 30);
      final useCase = CreateCampaign(
        repository: repository,
        idGenerator: () => 'generated-id',
        clock: () => localTime,
      );

      final campaign = await useCase('  La Corona Perdida  ');

      expect(campaign.id, 'generated-id');
      expect(campaign.name, 'La Corona Perdida');
      expect(campaign.createdAt, localTime.toUtc());
      expect(repository.savedCampaigns, hasLength(1));
      expect(repository.savedCampaigns.single, same(campaign));
    });

    test('propagates invalid campaign data without saving', () async {
      final repository = _RecordingCampaignRepository();
      final useCase = CreateCampaign(
        repository: repository,
        idGenerator: () => 'generated-id',
        clock: () => DateTime.utc(2026, 8, 10),
      );

      await expectLater(useCase('   '), throwsArgumentError);
      expect(repository.savedCampaigns, isEmpty);
    });
  });
}

final class _RecordingCampaignRepository implements CampaignRepository {
  final List<Campaign> savedCampaigns = <Campaign>[];

  @override
  Future<List<Campaign>> getAll() async => List<Campaign>.unmodifiable(savedCampaigns);

  @override
  Future<void> save(Campaign campaign) async {
    savedCampaigns.add(campaign);
  }
}

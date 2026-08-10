import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  group('Campaign', () {
    test('creates a valid campaign and trims id/name', () {
      final createdAt = DateTime.utc(2026, 8, 10, 12);

      final campaign = Campaign(
        id: ' campaign-1 ',
        name: ' La Corona Perdida ',
        createdAt: createdAt,
      );

      expect(campaign.id, 'campaign-1');
      expect(campaign.name, 'La Corona Perdida');
      expect(campaign.createdAt, createdAt);
      expect(campaign.updatedAt, createdAt);
      expect(campaign.isArchived, isFalse);
      expect(campaign.metadata.description, isNull);
      expect(campaign.metadata.tags, isEmpty);
      expect(campaign.configuration.aiEnabled, isTrue);
      expect(campaign.configuration.voiceEnabled, isTrue);
      expect(campaign.configuration.audioEnabled, isTrue);
    });

    test('rejects an empty id', () {
      expect(
        () => Campaign(
          id: '   ',
          name: 'Campaign',
          createdAt: DateTime.utc(2026, 8, 10),
        ),
        throwsArgumentError,
      );
    });

    test('rejects an empty name', () {
      expect(
        () => Campaign(
          id: 'campaign-1',
          name: '   ',
          createdAt: DateTime.utc(2026, 8, 10),
        ),
        throwsArgumentError,
      );
    });

    test('normalizes Campaign metadata', () {
      final metadata = CampaignMetadata(
        description: '  Campaña principal  ',
        tags: <String>[' Tierra Media ', 'epica', 'TIERRA MEDIA', '   '],
      );

      expect(metadata.description, 'Campaña principal');
      expect(metadata.tags, <String>['Tierra Media', 'epica']);
    });

    test('updates editable fields without changing identity', () {
      final createdAt = DateTime.utc(2026, 8, 10, 10);
      final updatedAt = DateTime.utc(2026, 8, 10, 11);
      final campaign = Campaign(
        id: 'campaign-1',
        name: 'Original',
        createdAt: createdAt,
      );
      final metadata = CampaignMetadata(
        description: 'Nueva descripción',
        tags: <String>['campaña'],
      );
      const configuration = CampaignConfiguration(
        aiEnabled: false,
        voiceEnabled: true,
        audioEnabled: false,
      );

      final updated = campaign.update(
        name: 'Nueva',
        metadata: metadata,
        configuration: configuration,
        at: updatedAt,
      );

      expect(updated.id, campaign.id);
      expect(updated.name, 'Nueva');
      expect(updated.createdAt, createdAt);
      expect(updated.updatedAt, updatedAt);
      expect(updated.metadata, same(metadata));
      expect(updated.configuration, same(configuration));
    });

    test('requires at least one editable field for update', () {
      final campaign = Campaign(
        id: 'campaign-1',
        name: 'Campaign',
        createdAt: DateTime.utc(2026, 8, 10, 10),
      );

      expect(
        () => campaign.update(at: DateTime.utc(2026, 8, 10, 11)),
        throwsArgumentError,
      );
    });

    test('renames without changing identity or creation time', () {
      final createdAt = DateTime.utc(2026, 8, 10, 10);
      final updatedAt = DateTime.utc(2026, 8, 10, 11);
      final campaign = Campaign(
        id: 'campaign-1',
        name: 'Original',
        createdAt: createdAt,
      );

      final renamed = campaign.rename(name: 'Nueva', at: updatedAt);

      expect(renamed.id, campaign.id);
      expect(renamed.name, 'Nueva');
      expect(renamed.createdAt, createdAt);
      expect(renamed.updatedAt, updatedAt);
      expect(renamed.isArchived, isFalse);
    });

    test('archives without destructive deletion and preserves campaign data', () {
      final createdAt = DateTime.utc(2026, 8, 10, 10);
      final archivedAt = DateTime.utc(2026, 8, 10, 12);
      final metadata = CampaignMetadata(
        description: 'Persistente',
        tags: <String>['tag'],
      );
      const configuration = CampaignConfiguration(aiEnabled: false);
      final campaign = Campaign(
        id: 'campaign-1',
        name: 'Campaign',
        createdAt: createdAt,
        metadata: metadata,
        configuration: configuration,
      );

      final archived = campaign.archive(at: archivedAt);

      expect(archived.id, campaign.id);
      expect(archived.isArchived, isTrue);
      expect(archived.archivedAt, archivedAt);
      expect(archived.updatedAt, archivedAt);
      expect(archived.metadata, same(metadata));
      expect(archived.configuration, same(configuration));
    });

    test('an archived campaign cannot be renamed', () {
      final campaign = Campaign(
        id: 'campaign-1',
        name: 'Campaign',
        createdAt: DateTime.utc(2026, 8, 10, 10),
      ).archive(at: DateTime.utc(2026, 8, 10, 11));

      expect(
        () => campaign.rename(
          name: 'Nueva',
          at: DateTime.utc(2026, 8, 10, 12),
        ),
        throwsStateError,
      );
    });
  });
}

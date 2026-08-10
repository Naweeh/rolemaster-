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

    test('archives without destructive deletion', () {
      final createdAt = DateTime.utc(2026, 8, 10, 10);
      final archivedAt = DateTime.utc(2026, 8, 10, 12);
      final campaign = Campaign(
        id: 'campaign-1',
        name: 'Campaign',
        createdAt: createdAt,
      );

      final archived = campaign.archive(at: archivedAt);

      expect(archived.id, campaign.id);
      expect(archived.isArchived, isTrue);
      expect(archived.archivedAt, archivedAt);
      expect(archived.updatedAt, archivedAt);
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

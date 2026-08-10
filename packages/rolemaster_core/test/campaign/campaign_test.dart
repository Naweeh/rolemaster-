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
  });
}

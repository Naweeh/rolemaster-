import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  group('CampaignState', () {
    test('creates an initial revision and advances monotonically', () {
      final initial = CampaignState.initial(' campaign-1 ');
      final changedAt = DateTime.utc(2026, 8, 10, 12);

      final next = initial.advance(changedAt);

      expect(initial.campaignId, 'campaign-1');
      expect(initial.revision, 0);
      expect(initial.updatedAt, isNull);
      expect(next.campaignId, 'campaign-1');
      expect(next.revision, 1);
      expect(next.updatedAt, changedAt);
    });

    test('rejects backwards state time', () {
      final state = CampaignState(
        campaignId: 'campaign-1',
        revision: 1,
        updatedAt: DateTime.utc(2026, 8, 10, 12),
      );

      expect(
        () => state.advance(DateTime.utc(2026, 8, 10, 11)),
        throwsArgumentError,
      );
    });

    test('enforces timestamp consistency with revision', () {
      expect(
        () => CampaignState(
          campaignId: 'campaign-1',
          revision: 0,
          updatedAt: DateTime.utc(2026, 8, 10),
        ),
        throwsArgumentError,
      );
      expect(
        () => CampaignState(campaignId: 'campaign-1', revision: 1),
        throwsArgumentError,
      );
    });
  });
}

import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:rolemaster_storage_sqlite/src/sqlite_campaign_state_repository.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteCampaignStateRepository', () {
    test('persists state after closing and reopening', () async {
      final fixture = await _createFixture('state-reopen');
      addTearDown(fixture.dispose);

      final writer = SqliteCampaignStateRepository.open(fixture.path);
      final saved = await writer.save(
        CampaignState(
          campaignId: 'campaign-1',
          revision: 1,
          updatedAt: DateTime.utc(2026, 8, 10, 12),
        ),
        expectedRevision: 0,
      );
      writer.close();

      final reader = SqliteCampaignStateRepository.open(fixture.path);
      final loaded = await reader.getByCampaignId('campaign-1');
      reader.close();

      expect(saved, isTrue);
      expect(loaded, isNotNull);
      expect(loaded!.revision, 1);
      expect(loaded.updatedAt, DateTime.utc(2026, 8, 10, 12));
    });

    test('returns false for a stale expected revision', () async {
      final fixture = await _createFixture('state-stale');
      addTearDown(fixture.dispose);
      final repository = SqliteCampaignStateRepository.open(fixture.path);
      addTearDown(repository.close);

      expect(
        await repository.save(
          CampaignState(
            campaignId: 'campaign-1',
            revision: 1,
            updatedAt: DateTime.utc(2026, 8, 10, 12),
          ),
          expectedRevision: 0,
        ),
        isTrue,
      );

      expect(
        await repository.save(
          CampaignState(
            campaignId: 'campaign-1',
            revision: 1,
            updatedAt: DateTime.utc(2026, 8, 10, 13),
          ),
          expectedRevision: 0,
        ),
        isFalse,
      );

      final loaded = await repository.getByCampaignId('campaign-1');
      expect(loaded!.revision, 1);
      expect(loaded.updatedAt, DateTime.utc(2026, 8, 10, 12));
    });

    test('advances only when stored revision matches expected revision',
        () async {
      final fixture = await _createFixture('state-update');
      addTearDown(fixture.dispose);
      final repository = SqliteCampaignStateRepository.open(fixture.path);
      addTearDown(repository.close);

      await repository.save(
        CampaignState(
          campaignId: 'campaign-1',
          revision: 1,
          updatedAt: DateTime.utc(2026, 8, 10, 12),
        ),
        expectedRevision: 0,
      );

      expect(
        await repository.save(
          CampaignState(
            campaignId: 'campaign-1',
            revision: 2,
            updatedAt: DateTime.utc(2026, 8, 10, 13),
          ),
          expectedRevision: 1,
        ),
        isTrue,
      );
      expect(
        await repository.save(
          CampaignState(
            campaignId: 'campaign-1',
            revision: 2,
            updatedAt: DateTime.utc(2026, 8, 10, 14),
          ),
          expectedRevision: 1,
        ),
        isFalse,
      );

      final loaded = await repository.getByCampaignId('campaign-1');
      expect(loaded!.revision, 2);
      expect(loaded.updatedAt, DateTime.utc(2026, 8, 10, 13));
    });

    test('two repository instances cannot both claim revision zero', () async {
      final fixture = await _createFixture('state-race');
      addTearDown(fixture.dispose);
      final first = SqliteCampaignStateRepository.open(fixture.path);
      final second = SqliteCampaignStateRepository.open(fixture.path);
      addTearDown(first.close);
      addTearDown(second.close);

      final firstResult = await first.save(
        CampaignState(
          campaignId: 'campaign-1',
          revision: 1,
          updatedAt: DateTime.utc(2026, 8, 10, 12),
        ),
        expectedRevision: 0,
      );
      final secondResult = await second.save(
        CampaignState(
          campaignId: 'campaign-1',
          revision: 1,
          updatedAt: DateTime.utc(2026, 8, 10, 13),
        ),
        expectedRevision: 0,
      );

      expect(firstResult, isTrue);
      expect(secondResult, isFalse);
      expect((await second.getByCampaignId('campaign-1'))!.revision, 1);
    });
  });
}

Future<_Fixture> _createFixture(String prefix) async {
  final directory = await Directory.systemTemp.createTemp('rolemaster_$prefix');
  final path = '${directory.path}${Platform.pathSeparator}rolemaster.db';
  final campaigns = SqliteCampaignRepository.open(path);
  await campaigns.save(
    Campaign(
      id: 'campaign-1',
      name: 'Campaña',
      createdAt: DateTime.utc(2026, 8, 10, 10),
    ),
  );
  campaigns.close();
  return _Fixture(path: path, directory: directory);
}

final class _Fixture {
  const _Fixture({required this.path, required this.directory});

  final String path;
  final Directory directory;

  Future<void> dispose() => directory.delete(recursive: true);
}

import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_state_sqlite.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteSnapshotService', () {
    test(
      'creates an immutable validated snapshot of the full database',
      () async {
        final fixture = await _createFixture('snapshot-create');
        addTearDown(fixture.dispose);
        final snapshotPath = '${fixture.directory.path}/campaign.snapshot.db';
        final service = SqliteSnapshotService();

        final info = await service.createSnapshot(
          sourcePath: fixture.path,
          snapshotPath: snapshotPath,
        );

        final live = sqlite3.open(fixture.path);
        live.execute(
          "UPDATE campaigns SET name = 'Campaña mutada' WHERE id = 'campaign-1'",
        );
        live.close();

        final snapshotCampaigns = SqliteCampaignRepository.open(snapshotPath);
        final campaign = await snapshotCampaigns.getById('campaign-1');
        snapshotCampaigns.close();
        final snapshotEvents = SqliteEventHistoryRepository.open(snapshotPath);
        final events = await snapshotEvents.getForCampaign('campaign-1');
        snapshotEvents.close();
        final snapshotStates = SqliteCampaignStateRepository.open(snapshotPath);
        final state = await snapshotStates.getByCampaignId('campaign-1');
        snapshotStates.close();

        expect(info.schemaVersion, SqliteCampaignStateRepository.schemaVersion);
        expect(info.sizeBytes, greaterThan(0));
        expect(campaign!.name, 'Campaña original');
        expect(events.map((event) => event.id), <String>['event-1']);
        expect(state!.revision, 1);
      },
    );

    test(
      'restores snapshot and preserves a pre-restore rollback copy',
      () async {
        final fixture = await _createFixture('snapshot-restore');
        addTearDown(fixture.dispose);
        final snapshotPath = '${fixture.directory.path}/campaign.snapshot.db';
        final service = SqliteSnapshotService();
        await service.createSnapshot(
          sourcePath: fixture.path,
          snapshotPath: snapshotPath,
        );

        final live = sqlite3.open(fixture.path);
        live.execute(
          "UPDATE campaigns SET name = 'Campaña mutada' WHERE id = 'campaign-1'",
        );
        live.close();

        final liveStates = SqliteCampaignStateRepository.open(fixture.path);
        expect(
          await liveStates.save(
            CampaignState(
              campaignId: 'campaign-1',
              revision: 2,
              updatedAt: DateTime.utc(2026, 8, 10, 13),
            ),
            expectedRevision: 1,
          ),
          isTrue,
        );
        liveStates.close();

        final liveEvents = SqliteEventHistoryRepository.open(fixture.path);
        await liveEvents.append(
          DomainEvent(
            id: 'event-2',
            type: DomainEventTypes.worldCreated,
            campaignId: 'campaign-1',
            occurredAt: DateTime.utc(2026, 8, 10, 13),
          ),
        );
        liveEvents.close();

        final result = await service.restoreSnapshot(
          snapshotPath: snapshotPath,
          destinationPath: fixture.path,
        );

        final restoredCampaigns = SqliteCampaignRepository.open(fixture.path);
        final restoredCampaign = await restoredCampaigns.getById('campaign-1');
        restoredCampaigns.close();
        final restoredStates = SqliteCampaignStateRepository.open(fixture.path);
        final restoredState = await restoredStates.getByCampaignId(
          'campaign-1',
        );
        restoredStates.close();
        final restoredEvents = SqliteEventHistoryRepository.open(fixture.path);
        final restoredHistory = await restoredEvents.getForCampaign(
          'campaign-1',
        );
        restoredEvents.close();

        expect(restoredCampaign!.name, 'Campaña original');
        expect(restoredState!.revision, 1);
        expect(restoredHistory.map((event) => event.id), <String>['event-1']);
        expect(
          result.schemaVersion,
          SqliteCampaignStateRepository.schemaVersion,
        );
        expect(result.rollbackPath, isNotNull);
        expect(await File(result.rollbackPath!).exists(), isTrue);

        final rollbackCampaigns = SqliteCampaignRepository.open(
          result.rollbackPath!,
        );
        final rollbackCampaign = await rollbackCampaigns.getById('campaign-1');
        rollbackCampaigns.close();
        final rollbackStates = SqliteCampaignStateRepository.open(
          result.rollbackPath!,
        );
        final rollbackState = await rollbackStates.getByCampaignId(
          'campaign-1',
        );
        rollbackStates.close();
        final rollbackEvents = SqliteEventHistoryRepository.open(
          result.rollbackPath!,
        );
        final rollbackHistory = await rollbackEvents.getForCampaign(
          'campaign-1',
        );
        rollbackEvents.close();

        expect(rollbackCampaign!.name, 'Campaña mutada');
        expect(rollbackState!.revision, 2);
        expect(rollbackHistory.map((event) => event.id), <String>[
          'event-1',
          'event-2',
        ]);
      },
    );

    test('logs snapshot lifecycle without campaign content', () async {
      final fixture = await _createFixture('snapshot-logging');
      addTearDown(fixture.dispose);
      final logger = _RecordingSqliteLogger();
      await SqliteSnapshotService(logger: logger).createSnapshot(
        sourcePath: fixture.path,
        snapshotPath: '${fixture.directory.path}/logged.snapshot',
      );

      expect(logger.events.map((item) => item.$1), <String>[
        'snapshot.create.started',
        'snapshot.create.completed',
      ]);
      final completion = logger.events.last.$2;
      expect(
        completion['schemaVersion'],
        SqliteCampaignRepository.schemaVersion,
      );
      expect(completion.containsKey('campaignId'), isFalse);
      expect(completion.containsKey('campaignName'), isFalse);
    });

    test('rejects invalid snapshots without touching live database', () async {
      final fixture = await _createFixture('snapshot-invalid');
      addTearDown(fixture.dispose);
      final invalidPath = '${fixture.directory.path}/invalid.snapshot';
      await File(invalidPath).writeAsString('not a sqlite database');
      final service = SqliteSnapshotService();

      await expectLater(
        service.restoreSnapshot(
          snapshotPath: invalidPath,
          destinationPath: fixture.path,
        ),
        throwsA(isA<SqliteSnapshotException>()),
      );

      final campaigns = SqliteCampaignRepository.open(fixture.path);
      final campaign = await campaigns.getById('campaign-1');
      campaigns.close();
      expect(campaign!.name, 'Campaña original');
    });

    test('rejects snapshots from a future schema version', () async {
      final fixture = await _createFixture('snapshot-future');
      addTearDown(fixture.dispose);
      final snapshotPath = '${fixture.directory.path}/future.snapshot.db';
      final service = SqliteSnapshotService();
      await service.createSnapshot(
        sourcePath: fixture.path,
        snapshotPath: snapshotPath,
      );

      final database = sqlite3.open(snapshotPath);
      database.userVersion = 999;
      database.close();

      await expectLater(
        service.validateSnapshot(snapshotPath),
        throwsA(isA<SqliteSnapshotException>()),
      );
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
      name: 'Campaña original',
      createdAt: DateTime.utc(2026, 8, 10, 10),
    ),
  );
  campaigns.close();

  final events = SqliteEventHistoryRepository.open(path);
  await events.append(
    DomainEvent(
      id: 'event-1',
      type: DomainEventTypes.campaignUpdated,
      campaignId: 'campaign-1',
      occurredAt: DateTime.utc(2026, 8, 10, 11),
    ),
  );
  events.close();

  final states = SqliteCampaignStateRepository.open(path);
  expect(
    await states.save(
      CampaignState(
        campaignId: 'campaign-1',
        revision: 1,
        updatedAt: DateTime.utc(2026, 8, 10, 12),
      ),
      expectedRevision: 0,
    ),
    isTrue,
  );
  states.close();

  return _Fixture(path: path, directory: directory);
}

final class _Fixture {
  const _Fixture({required this.path, required this.directory});

  final String path;
  final Directory directory;

  Future<void> dispose() => directory.delete(recursive: true);
}

final class _RecordingSqliteLogger implements SqliteOperationLogger {
  final events = <(String, Map<String, Object?>)>[];

  @override
  void record(String event, Map<String, Object?> fields) {
    events.add((event, Map<String, Object?>.of(fields)));
  }
}

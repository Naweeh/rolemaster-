import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:test/test.dart';

void main() {
  test('restore closes every managed live repository before replacing DB', () async {
    final directory = await Directory.systemTemp.createTemp('rolemaster-restore-');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/campaign.db';
    final snapshotPath = '${directory.path}/saved.db';
    final coordinator = SqliteApplicationCoordinator();

    ManagedSqliteRepository<SqliteCampaignRepository> openCampaign() =>
        coordinator.openRepository(
          databasePath: path,
          open: SqliteCampaignRepository.open,
          close: (repository) => repository.close(),
        );

    final campaigns = openCampaign();
    final original = Campaign(
      id: 'campaign-1',
      name: 'Original',
      createdAt: DateTime.utc(2026, 9, 27),
    );
    await campaigns.repository.save(original);
    await SqliteSnapshotService().createSnapshot(
      sourcePath: path,
      snapshotPath: snapshotPath,
    );

    final secondConnection = coordinator.openRepository(
      databasePath: path,
      open: SqliteEventHistoryRepository.open,
      close: (SqliteEventHistoryRepository repository) => repository.close(),
    );
    await campaigns.repository.save(
      original.rename(name: 'Changed', at: DateTime.utc(2026, 9, 28)),
    );

    final result = await coordinator.restoreSnapshot(
      snapshotPath: snapshotPath,
      destinationPath: path,
    );

    expect(campaigns.isClosed, isTrue);
    expect(secondConnection.isClosed, isTrue);
    expect(result.rollbackPath, isNotNull);
    final reopened = openCampaign();
    expect((await reopened.repository.getById(original.id))?.name, 'Original');
    reopened.close();
  });
}

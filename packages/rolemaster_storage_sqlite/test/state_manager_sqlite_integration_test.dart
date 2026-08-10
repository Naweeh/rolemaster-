import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_state_sqlite.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:test/test.dart';

void main() {
  test(
    'StateManager persists authoritative revisions through SQLite',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'rolemaster_state_manager_sqlite_',
      );
      final path = '${directory.path}${Platform.pathSeparator}rolemaster.db';
      addTearDown(() => directory.delete(recursive: true));

      final campaigns = SqliteCampaignRepository.open(path);
      await campaigns.save(
        Campaign(
          id: 'campaign-1',
          name: 'Campaña',
          createdAt: DateTime.utc(2026, 8, 10, 10),
        ),
      );
      campaigns.close();

      final stateRepository = SqliteCampaignStateRepository.open(path);
      final manager = StateManager(repository: stateRepository);
      final externalValue = <String>[];

      final first = await manager.execute(
        StateTransaction(
          campaignId: 'campaign-1',
          expectedRevision: 0,
          changes: <StateChange>[
            _ListAppendChange(values: externalValue, value: 'first'),
          ],
          changedAt: DateTime.utc(2026, 8, 10, 12),
        ),
      );
      expect(first.revision, 1);
      expect(externalValue, <String>['first']);
      stateRepository.close();

      final reopenedRepository = SqliteCampaignStateRepository.open(path);
      final reopenedManager = StateManager(repository: reopenedRepository);
      final restored = await reopenedManager.getState('campaign-1');
      expect(restored.revision, 1);

      final second = await reopenedManager.execute(
        StateTransaction(
          campaignId: 'campaign-1',
          expectedRevision: 1,
          changes: <StateChange>[
            _ListAppendChange(values: externalValue, value: 'second'),
          ],
          changedAt: DateTime.utc(2026, 8, 10, 13),
        ),
      );
      expect(second.revision, 2);
      expect(externalValue, <String>['first', 'second']);
      reopenedRepository.close();

      final verificationRepository = SqliteCampaignStateRepository.open(path);
      final persisted = await verificationRepository.getByCampaignId(
        'campaign-1',
      );
      verificationRepository.close();

      expect(persisted, isNotNull);
      expect(persisted!.revision, 2);
      expect(persisted.updatedAt, DateTime.utc(2026, 8, 10, 13));
    },
  );
}

final class _ListAppendChange implements StateChange {
  _ListAppendChange({required this.values, required this.value});

  final List<String> values;
  final String value;

  @override
  Future<void> validate() async {
    if (value.isEmpty) {
      throw ArgumentError('Value cannot be empty.');
    }
  }

  @override
  Future<void> apply() async {
    values.add(value);
  }

  @override
  Future<void> rollback() async {
    if (values.isNotEmpty && values.last == value) {
      values.removeLast();
    }
  }
}

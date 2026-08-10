import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_state_sqlite.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:test/test.dart';

void main() {
  test('adding campaign state preserves existing v5 event history', () async {
    final directory = await Directory.systemTemp.createTemp(
      'rolemaster_state_compatibility_',
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

    final events = SqliteEventHistoryRepository.open(path);
    await events.append(
      DomainEvent(
        id: 'event-1',
        type: DomainEventTypes.campaignUpdated,
        campaignId: 'campaign-1',
        occurredAt: DateTime.utc(2026, 8, 10, 11),
        payload: const <String, Object?>{'source': 'before-state-manager'},
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

    final reopenedEvents = SqliteEventHistoryRepository.open(path);
    final preserved = await reopenedEvents.getById('event-1');
    reopenedEvents.close();

    final reopenedStates = SqliteCampaignStateRepository.open(path);
    final state = await reopenedStates.getByCampaignId('campaign-1');
    reopenedStates.close();

    expect(preserved, isNotNull);
    expect(preserved!.payload['source'], 'before-state-manager');
    expect(state, isNotNull);
    expect(state!.revision, 1);
  });
}

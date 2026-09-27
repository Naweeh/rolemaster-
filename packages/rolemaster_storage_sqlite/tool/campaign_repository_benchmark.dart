import 'dart:convert';
import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';

const int _sampleSize = 500;
const int _combatRevisions = 200;
const int _rounds = 4;
const int _warmupRounds = 1;

Future<void> main() async {
  final results = <Map<String, Object>>[
    await _measure(
      name: 'sqlite_campaign_repository',
      iterations: _sampleSize,
      runRound: _campaignRound,
    ),
    await _measure(
      name: 'sqlite_event_history_repository',
      iterations: _sampleSize,
      runRound: _eventHistoryRound,
    ),
    await _measure(
      name: 'sqlite_combat_state_repository',
      iterations: _combatRevisions,
      runRound: _combatStateRound,
    ),
  ];

  // ignore: avoid_print
  print(
    jsonEncode(<String, Object>{
      'benchmarkSuite': 'rolemaster_sqlite_repositories',
      'warmupRounds': _warmupRounds,
      'measuredRounds': _rounds - _warmupRounds,
      'operatingSystem': Platform.operatingSystem,
      'runtime': Platform.version,
      'processors': Platform.numberOfProcessors,
      'results': results,
      'comparisonPolicy':
          'Informational; compare medians on the same OS and runtime.',
    }),
  );
}

Future<Map<String, Object>> _measure({
  required String name,
  required int iterations,
  required Future<({int writes, int reads})> Function(int round) runRound,
}) async {
  final writeSamples = <int>[];
  final readSamples = <int>[];

  for (var round = 0; round < _rounds; round++) {
    final sample = await runRound(round);
    if (round >= _warmupRounds) {
      writeSamples.add(sample.writes);
      readSamples.add(sample.reads);
    }
  }

  return <String, Object>{
    'benchmark': name,
    'iterationsPerRound': iterations,
    'medianWriteMicroseconds': _median(writeSamples),
    'medianReadMicroseconds': _median(readSamples),
  };
}

Future<({int writes, int reads})> _campaignRound(int round) async {
  final directory = await Directory.systemTemp.createTemp(
    'rolemaster_campaign_bench',
  );
  final path = '${directory.path}/campaign.sqlite';
  final repository = SqliteCampaignRepository.open(path);

  try {
    final write = Stopwatch()..start();
    for (var item = 0; item < _sampleSize; item++) {
      await repository.save(
        Campaign(
          id: 'r$round-c$item',
          name: 'Benchmark campaign $item',
          createdAt: DateTime.utc(2026),
        ),
      );
    }
    write.stop();

    final read = Stopwatch()..start();
    for (var item = 0; item < _sampleSize; item++) {
      await repository.getById('r$round-c$item');
    }
    read.stop();

    return (writes: write.elapsedMicroseconds, reads: read.elapsedMicroseconds);
  } finally {
    repository.close();
    await directory.delete(recursive: true);
  }
}

Future<({int writes, int reads})> _eventHistoryRound(int round) async {
  final directory = await Directory.systemTemp.createTemp(
    'rolemaster_events_bench',
  );
  final path = '${directory.path}/events.sqlite';
  final campaigns = SqliteCampaignRepository.open(path);
  await campaigns.save(
    Campaign(
      id: 'benchmark-campaign',
      name: 'Benchmark campaign',
      createdAt: DateTime.utc(2026),
    ),
  );
  campaigns.close();

  final repository = SqliteEventHistoryRepository.open(path);
  try {
    final write = Stopwatch()..start();
    for (var item = 0; item < _sampleSize; item++) {
      await repository.append(
        DomainEvent(
          id: 'r$round-event-$item',
          type: DomainEventTypes.campaignUpdated,
          campaignId: 'benchmark-campaign',
          occurredAt: DateTime.utc(2026).add(Duration(seconds: item)),
          payload: <String, Object?>{'sequence': item},
        ),
      );
    }
    write.stop();

    final read = Stopwatch()..start();
    final events = await repository.getForCampaign(
      'benchmark-campaign',
      limit: _sampleSize,
    );
    read.stop();

    if (events.length != _sampleSize) {
      throw StateError('Expected $_sampleSize events, found ${events.length}.');
    }
    return (writes: write.elapsedMicroseconds, reads: read.elapsedMicroseconds);
  } finally {
    repository.close();
    await directory.delete(recursive: true);
  }
}

Future<({int writes, int reads})> _combatStateRound(int round) async {
  final directory = await Directory.systemTemp.createTemp(
    'rolemaster_combat_bench',
  );
  final path = '${directory.path}/combat.sqlite';
  final campaigns = SqliteCampaignRepository.open(path);
  await campaigns.save(
    Campaign(
      id: 'benchmark-campaign',
      name: 'Benchmark campaign',
      createdAt: DateTime.utc(2026),
    ),
  );
  campaigns.close();

  final encounters = SqliteEncounterRepository.open(path);
  await encounters.save(
    Encounter(
      id: 'benchmark-encounter',
      campaignId: 'benchmark-campaign',
      name: 'Benchmark encounter',
      status: EncounterStatus.active,
      participants: <EncounterParticipant>[
        EncounterParticipant(entityType: 'character', entityId: 'hero'),
        EncounterParticipant(entityType: 'npc', entityId: 'guide'),
      ],
      createdAt: DateTime.utc(2026),
      startedAt: DateTime.utc(2026),
    ),
  );
  encounters.close();

  final repository = SqliteCombatStateRepository.open(path);
  try {
    var state = CombatState(
      encounterId: 'benchmark-encounter',
      campaignId: 'benchmark-campaign',
      rulesetId: 'benchmark-ruleset',
      rulesetVersion: '1',
      stats: const <String, Map<String, int>>{
        'character:hero': <String, int>{'stamina': 10},
        'npc:guide': <String, int>{'stamina': 10},
      },
      turnOrder: <CombatParticipant>[
        CombatParticipant(
          entityType: 'character',
          entityId: 'hero',
          name: 'Hero',
        ),
        CombatParticipant(entityType: 'npc', entityId: 'guide', name: 'Guide'),
      ],
    );
    await repository.save(state);

    final write = Stopwatch()..start();
    for (var revision = 0; revision < _combatRevisions; revision++) {
      state = state.advanceTurn();
      await repository.save(state);
    }
    write.stop();

    final read = Stopwatch()..start();
    final restored = await repository.getByEncounterId('benchmark-encounter');
    read.stop();

    if (restored?.revision != _combatRevisions) {
      throw StateError(
        'Combat state did not reach revision $_combatRevisions.',
      );
    }
    return (writes: write.elapsedMicroseconds, reads: read.elapsedMicroseconds);
  } finally {
    repository.close();
    await directory.delete(recursive: true);
  }
}

int _median(List<int> values) {
  final sorted = values.toList()..sort();
  return sorted[sorted.length ~/ 2];
}

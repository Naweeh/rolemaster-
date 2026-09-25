import 'dart:convert';
import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';

Future<void> main() async {
  const sampleSize = 500;
  final directory = await Directory.systemTemp.createTemp('rolemaster_bench');
  final path = '${directory.path}/benchmark.sqlite';
  final repository = SqliteCampaignRepository.open(path);
  final writeSamples = <int>[];
  final readSamples = <int>[];

  try {
    for (var round = 0; round < 4; round++) {
      final write = Stopwatch()..start();
      for (var item = 0; item < sampleSize; item++) {
        await repository.save(Campaign(
          id: 'r$round-c$item',
          name: 'Benchmark campaign $item',
          createdAt: DateTime.utc(2026),
        ));
      }
      write.stop();

      final read = Stopwatch()..start();
      for (var item = 0; item < sampleSize; item++) {
        await repository.getById('r$round-c$item');
      }
      read.stop();
      if (round > 0) {
        writeSamples.add(write.elapsedMicroseconds);
        readSamples.add(read.elapsedMicroseconds);
      }
    }
  } finally {
    repository.close();
    await directory.delete(recursive: true);
  }

  print(jsonEncode(<String, Object>{
    'benchmark': 'sqlite_campaign_repository',
    'iterationsPerRound': sampleSize,
    'measuredRounds': writeSamples.length,
    'warmupRounds': 1,
    'medianWriteMicroseconds': _median(writeSamples),
    'medianReadMicroseconds': _median(readSamples),
    'note': 'Informational only; compare on the same machine and runtime.',
  }));
}

int _median(List<int> values) {
  final sorted = values.toList()..sort();
  return sorted[sorted.length ~/ 2];
}

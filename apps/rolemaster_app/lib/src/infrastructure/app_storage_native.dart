import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';

import 'app_storage.dart';

Future<AppStorage> openAppStorage(RulesetPackage package) async {
  final directory = await getApplicationSupportDirectory();
  return openNativeAppStorageAt(
    '${directory.path}${Platform.pathSeparator}rolemaster.db',
    package,
  );
}

/// Explicit path supports reopen tests without platform directory channels.
Future<AppStorage> openNativeAppStorageAt(
  String path,
  RulesetPackage package,
) async {
  await File(path).parent.create(recursive: true);
  final coordinator = SqliteApplicationCoordinator();
  final handles = <void Function()>[];
  try {
    final campaigns = coordinator.openRepository(
      databasePath: path,
      open: SqliteCampaignRepository.open,
      close: (SqliteCampaignRepository repository) => repository.close(),
    );
    handles.add(campaigns.close);
    final characters = coordinator.openRepository(
      databasePath: path,
      open: SqliteCharacterRepository.open,
      close: (SqliteCharacterRepository repository) => repository.close(),
    );
    handles.add(characters.close);
    final rulesets = coordinator.openRepository(
      databasePath: path,
      open: SqliteRulesetRepository.open,
      close: (SqliteRulesetRepository repository) => repository.close(),
    );
    handles.add(rulesets.close);
    final campaignRulesets = coordinator.openRepository(
      databasePath: path,
      open: SqliteCampaignRulesetRepository.open,
      close: (SqliteCampaignRulesetRepository repository) => repository.close(),
    );
    handles.add(campaignRulesets.close);

    if (await rulesets.repository.getPackage(
          rulesetId: package.manifest.id,
          version: package.manifest.version,
        ) ==
        null) {
      await rulesets.repository.publish(package);
    }
    final storage = AppStorage(
      campaigns: campaigns.repository,
      characters: characters.repository,
      rulesets: rulesets.repository,
      campaignRulesets: campaignRulesets.repository,
      close: () {
        for (final close in handles.reversed) {
          close();
        }
      },
    );
    await initializeVisualAlphaCampaign(storage, package);
    return storage;
  } catch (_) {
    for (final close in handles.reversed) {
      close();
    }
    rethrow;
  }
}

import 'package:flutter/material.dart';

import 'src/app/error_logging.dart';
import 'src/app/rolemaster_app.dart';
import 'src/infrastructure/app_storage_memory.dart'
    if (dart.library.io) 'src/infrastructure/app_storage_native.dart'
    as storage;
import 'src/infrastructure/manual_alpha_rulesets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installRolemasterErrorLogging();

  final manualRulesets = buildManualAlphaRulesets();
  final appStorage = await storage.openAppStorage(manualRulesets.single);

  runApp(
    RolemasterApp(
      campaignRepository: appStorage.campaigns,
      characterRepository: appStorage.characters,
      characterProfileRepository: appStorage.characterProfiles,
      rulesetRepository: appStorage.rulesets,
      campaignRulesetRepository: appStorage.campaignRulesets,
    ),
  );
}

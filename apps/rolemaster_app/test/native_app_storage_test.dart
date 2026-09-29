import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rolemaster_app/src/infrastructure/app_storage_native.dart';
import 'package:rolemaster_app/src/infrastructure/manual_alpha_rulesets.dart';
import 'package:rolemaster_core/rolemaster_core.dart';

void main() {
  test('native session reopens campaign and exact ruleset binding', () async {
    final directory = await Directory.systemTemp.createTemp('rolemaster-app-');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/rolemaster.db';
    final package = buildManualAlphaRulesets().single;

    final first = await openNativeAppStorageAt(path, package);
    final campaign = await first.campaigns.getById('visual-alpha-dnd');
    expect(campaign, isNotNull);
    await first.campaigns.save(
      campaign!.rename(
        name: 'Persisted campaign',
        at: DateTime.utc(2026, 9, 29),
      ),
    );
    first.close();

    final reopened = await openNativeAppStorageAt(path, package);
    addTearDown(reopened.close);
    expect(
      (await reopened.campaigns.getById('visual-alpha-dnd'))?.name,
      'Persisted campaign',
    );
    final state = await reopened.campaignRulesets.getForCampaign(
      'visual-alpha-dnd',
    );
    expect(state?.binding.rulesetId, package.manifest.id);
    expect(state?.binding.rulesetVersion, package.manifest.version);
    expect(
      await reopened.rulesets.getPackage(
        rulesetId: package.manifest.id,
        version: package.manifest.version,
      ),
      isA<RulesetPackage>(),
    );
  });
}

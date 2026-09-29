import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rolemaster_app/src/features/visual_alpha/visual_alpha_character_profile.dart';
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
    final createCharacter = CreateCharacter(
      repository: first.characters,
      campaignRepository: first.campaigns,
      idGenerator: () => 'pc-1',
      clock: () => DateTime.utc(2026, 9, 29),
    );
    await createCharacter(campaignId: 'visual-alpha-dnd', name: 'Hero');
    await first.characterProfiles.save(
      VisualAlphaCharacterProfile(
        characterId: 'pc-1',
        rulesetId: package.manifest.id,
        rulesetVersion: package.manifest.version,
        className: 'Fighter',
        alignment: 'Neutral',
        abilities: <String, int>{'STR': 14},
        startingGold: 100,
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
    final profile = await reopened.characterProfiles.getForCharacter('pc-1');
    expect(profile?.abilities['STR'], 14);
    expect(profile?.className, 'Fighter');
    expect(profile?.startingGold, 100);
    expect(
      await reopened.rulesets.getPackage(
        rulesetId: package.manifest.id,
        version: package.manifest.version,
      ),
      isA<RulesetPackage>(),
    );
  });
}

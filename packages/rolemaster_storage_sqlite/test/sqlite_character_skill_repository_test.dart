import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteCharacterSkillRepository', () {
    test('persists ranks, modifiers and notes after reopening', () async {
      final fixture = await _createFixture('skill-reopen');
      addTearDown(fixture.dispose);

      final writer = SqliteCharacterSkillRepository.open(fixture.path);
      await writer.save(
        CharacterSkillState(
          characterId: 'character-1',
          skillId: 'perception',
          ranks: 4,
          modifiers: const <String, int>{'stat': 6, 'profession': 10},
          notes: 'Entrenamiento de frontera',
          updatedAt: DateTime.utc(2026, 8, 10, 15),
        ),
      );
      writer.close();

      final reader = SqliteCharacterSkillRepository.open(fixture.path);
      final loaded = await reader.getByCharacterAndSkill(
        characterId: 'character-1',
        skillId: 'perception',
      );
      reader.close();

      expect(loaded, isNotNull);
      expect(loaded!.ranks, 4);
      expect(loaded.modifierTotal, 16);
      expect(loaded.notes, 'Entrenamiento de frontera');
    });

    test('upserts the same character skill without duplication', () async {
      final fixture = await _createFixture('skill-update');
      addTearDown(fixture.dispose);
      final repository = SqliteCharacterSkillRepository.open(fixture.path);
      addTearDown(repository.close);

      await repository.save(
        CharacterSkillState(
          characterId: 'character-1',
          skillId: 'perception',
          ranks: 2,
          updatedAt: DateTime.utc(2026, 8, 10, 14),
        ),
      );
      await repository.save(
        CharacterSkillState(
          characterId: 'character-1',
          skillId: 'perception',
          ranks: 5,
          modifiers: const <String, int>{'stat': 8},
          updatedAt: DateTime.utc(2026, 8, 10, 15),
        ),
      );

      final all = await repository.getForCharacter('character-1');
      expect(all, hasLength(1));
      expect(all.single.ranks, 5);
      expect(all.single.modifiers, <String, int>{'stat': 8});
    });

    test('migrates v10 to v11 without losing ruleset binding', () async {
      final fixture = await _createFixture('skill-migration', withRuleset: true);
      addTearDown(fixture.dispose);

      final legacy = sqlite3.open(fixture.path);
      legacy.execute('DROP TABLE character_skills');
      legacy.execute('PRAGMA user_version = 10');
      legacy.close();

      final skills = SqliteCharacterSkillRepository.open(fixture.path);
      await skills.save(
        CharacterSkillState(
          characterId: 'character-1',
          skillId: 'perception',
          ranks: 1,
          updatedAt: DateTime.utc(2026, 8, 10, 15),
        ),
      );
      skills.close();

      final rulesets = SqliteCampaignRulesetRepository.open(fixture.path);
      final binding = await rulesets.getForCampaign('campaign-1');
      rulesets.close();
      final database = sqlite3.open(fixture.path);
      final version = database.select('PRAGMA user_version').single;
      database.close();

      expect(version['user_version'], SqliteCharacterSkillRepository.schemaVersion);
      expect(binding, isNotNull);
      expect(binding!.binding.rulesetId, 'rolemaster-demo');
      expect(binding.binding.rulesetVersion, '0.2.0');
    });
  });
}

Future<_Fixture> _createFixture(
  String prefix, {
  bool withRuleset = false,
}) async {
  final directory = await Directory.systemTemp.createTemp('rolemaster_$prefix');
  final path = '${directory.path}${Platform.pathSeparator}rolemaster.db';

  final campaigns = SqliteCampaignRepository.open(path);
  await campaigns.save(
    Campaign(
      id: 'campaign-1',
      name: 'Campaña',
      createdAt: DateTime.utc(2026, 8, 10, 10),
    ),
  );
  campaigns.close();

  final characters = SqliteCharacterRepository.open(path);
  await characters.save(
    Character(
      id: 'character-1',
      campaignId: 'campaign-1',
      name: 'Aria',
      createdAt: DateTime.utc(2026, 8, 10, 11),
    ),
  );
  characters.close();

  if (withRuleset) {
    final packages = SqliteRulesetRepository.open(path);
    await packages.publish(
      RulesetPackage(
        manifest: RulesetManifest(
          id: 'rolemaster-demo',
          systemId: 'rolemaster',
          edition: 'Demo',
          version: '0.2.0',
          displayName: 'Rolemaster Demo',
          modules: <RulesetModuleDefinition>[
            RulesetModuleDefinition(id: 'core', name: 'Core', required: true),
          ],
        ),
        data: const <String, Object?>{
          'skills': <Object?>[
            <String, Object?>{
              'id': 'perception',
              'name': 'Perception',
              'moduleId': 'core',
            },
          ],
        },
      ),
    );
    packages.close();

    final campaignRulesets = SqliteCampaignRulesetRepository.open(path);
    await campaignRulesets.save(
      CampaignRulesetState(
        binding: CampaignRulesetBinding(
          campaignId: 'campaign-1',
          rulesetId: 'rolemaster-demo',
          rulesetVersion: '0.2.0',
          activeModuleIds: <String>['core'],
          boundAt: DateTime.utc(2026, 8, 10, 12),
        ),
        overlay: CampaignRulesOverlay.clean(
          campaignId: 'campaign-1',
          updatedAt: DateTime.utc(2026, 8, 10, 12),
        ),
      ),
    );
    campaignRulesets.close();
  }

  return _Fixture(path: path, directory: directory);
}

final class _Fixture {
  const _Fixture({required this.path, required this.directory});

  final String path;
  final Directory directory;

  Future<void> dispose() => directory.delete(recursive: true);
}

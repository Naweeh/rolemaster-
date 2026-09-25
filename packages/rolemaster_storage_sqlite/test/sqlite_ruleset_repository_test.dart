import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteRulesetRepository', () {
    test('publishes immutable versioned packages and reloads them', () async {
      final fixture = await _createFixture('ruleset-package');
      addTearDown(fixture.dispose);
      final repository = SqliteRulesetRepository.open(fixture.path);
      addTearDown(repository.close);

      final package = _package();
      await repository.publish(package);

      final loaded = await repository.getPackage(
        rulesetId: 'rolemaster-rm2',
        version: '1.0.0',
      );
      final available = await repository.getAvailablePackages();

      expect(loaded, isNotNull);
      expect(loaded!.manifest.edition, 'RM2');
      expect(loaded.manifest.modules, hasLength(3));
      expect(loaded.data['tables'], isNotNull);
      expect(available, hasLength(1));
      await expectLater(repository.publish(package), throwsStateError);
    });

    test('persists campaign binding and a campaign-local overlay', () async {
      final fixture = await _createFixture('ruleset-binding');
      addTearDown(fixture.dispose);

      final packages = SqliteRulesetRepository.open(fixture.path);
      await packages.publish(_package());
      packages.close();

      final writer = SqliteCampaignRulesetRepository.open(fixture.path);
      await writer.save(
        CampaignRulesetState(
          binding: CampaignRulesetBinding(
            campaignId: 'campaign-1',
            rulesetId: 'rolemaster-rm2',
            rulesetVersion: '1.0.0',
            activeModuleIds: <String>['core', 'arms-law'],
            boundAt: DateTime.utc(2026, 8, 10, 12),
          ),
          overlay: CampaignRulesOverlay(
            campaignId: 'campaign-1',
            updatedAt: DateTime.utc(2026, 8, 10, 13),
            overrides: const <String, Object?>{
              'houseRules': <String, Object?>{'openEndedRoll': false},
            },
          ),
        ),
      );
      writer.close();

      final reader = SqliteCampaignRulesetRepository.open(fixture.path);
      final loaded = await reader.getForCampaign('campaign-1');
      reader.close();

      expect(loaded, isNotNull);
      expect(loaded!.binding.rulesetVersion, '1.0.0');
      expect(loaded.binding.activeModuleIds, <String>['core', 'arms-law']);
      expect(loaded.overlay.isClean, isFalse);
      final houseRules =
          loaded.overlay.overrides['houseRules']! as Map<String, Object?>;
      expect(houseRules['openEndedRoll'], isFalse);
    });

    test('blocks silent ruleset version replacement', () async {
      final fixture = await _createFixture('ruleset-replacement');
      addTearDown(fixture.dispose);
      final packages = SqliteRulesetRepository.open(fixture.path);
      await packages.publish(_package());
      await packages.publish(_package(version: '1.1.0'));
      packages.close();

      final repository = SqliteCampaignRulesetRepository.open(fixture.path);
      addTearDown(repository.close);
      await repository.save(_cleanState(version: '1.0.0'));

      await expectLater(
        repository.save(_cleanState(version: '1.1.0')),
        throwsStateError,
      );
    });

    test(
      'controlled migration is atomic and requires closed encounters',
      () async {
        final fixture = await _createFixture('ruleset-controlled-migration');
        addTearDown(fixture.dispose);
        final packages = SqliteRulesetRepository.open(fixture.path);
        await packages.publish(_package());
        await packages.publish(_package(version: '2.0.0'));
        addTearDown(packages.close);
        final bindings = SqliteCampaignRulesetRepository.open(fixture.path);
        addTearDown(bindings.close);
        final initial = _cleanState(version: '1.0.0');
        await bindings.save(
          CampaignRulesetState(
            binding: initial.binding,
            overlay: initial.overlay.replaceOverrides(const <String, Object?>{
              'tables': <String, Object?>{
                'critical-e': <String, Object?>{'max': 90},
              },
            }, at: DateTime.utc(2026, 8, 10, 13)),
          ),
        );
        final campaigns = SqliteCampaignRepository.open(fixture.path);
        addTearDown(campaigns.close);
        final migrate = MigrateCampaignRuleset(
          campaignRepository: campaigns,
          rulesetRepository: packages,
          campaignRulesetRepository: bindings,
          clock: () => DateTime.utc(2026, 8, 11),
        );
        final database = sqlite3.open(fixture.path);
        addTearDown(database.close);
        database.execute('''INSERT INTO encounters
           (id, campaign_id, name, status, created_at, updated_at, started_at)
           VALUES ('enc-1', 'campaign-1', 'Fight', 'active', 1, 1, 1)''');
        Future<CampaignRulesetState> execute({
          bool preserveOverlay = false,
          CampaignRulesOverlayTransformer? overlayTransformer,
        }) => migrate(
          campaignId: 'campaign-1',
          targetRulesetId: 'rolemaster-rm2',
          targetVersion: '2.0.0',
          expectedSourceVersion: '1.0.0',
          preserveOverlay: preserveOverlay,
          overlayTransformer: overlayTransformer,
        );
        await expectLater(execute(), throwsStateError);
        expect(
          (await bindings.getForCampaign('campaign-1'))!.binding.rulesetVersion,
          '1.0.0',
        );
        database.execute(
          "UPDATE encounters SET status = 'closed', closed_at = 2 WHERE id = 'enc-1'",
        );
        await expectLater(execute(preserveOverlay: true), throwsStateError);
        final result = await execute(
          preserveOverlay: true,
          overlayTransformer:
              ({
                required sourcePackage,
                required targetPackage,
                required sourceOverrides,
              }) => const <String, Object?>{
                'tables': <String, Object?>{
                  'critical-e': <String, Object?>{'max': 95},
                },
              },
        );
        expect(result.binding.rulesetVersion, '2.0.0');
        final migratedTable =
            result.overlay.overrides['tables']! as Map<String, Object?>;
        expect(
          (migratedTable['critical-e']! as Map<String, Object?>)['max'],
          95,
        );
        expect(
          (await bindings.getForCampaign('campaign-1'))!.binding.rulesetVersion,
          '2.0.0',
        );
        await expectLater(execute(), throwsStateError);
        await expectLater(
          bindings.save(_cleanState(version: '1.0.0')),
          throwsStateError,
        );
      },
    );

    test('migrates stored skills and item definitions atomically', () async {
      final fixture = await _createFixture('ruleset-content-migration');
      addTearDown(fixture.dispose);
      final packages = SqliteRulesetRepository.open(fixture.path);
      await packages.publish(_package());
      await packages.publish(_package(version: '2.0.0'));
      addTearDown(packages.close);

      final campaigns = SqliteCampaignRepository.open(fixture.path);
      await campaigns.save(
        Campaign(
          id: 'campaign-rollback',
          name: 'Rollback',
          createdAt: DateTime.utc(2026, 8, 10, 10),
        ),
      );
      addTearDown(campaigns.close);
      final characters = SqliteCharacterRepository.open(fixture.path);
      for (final id in <String>['character-1', 'character-rollback']) {
        await characters.save(
          Character(
            id: id,
            campaignId: id == 'character-1'
                ? 'campaign-1'
                : 'campaign-rollback',
            name: id,
            createdAt: DateTime.utc(2026, 8, 10, 11),
          ),
        );
      }
      characters.close();

      final skills = SqliteCharacterSkillRepository.open(fixture.path);
      for (final id in <String>['character-1', 'character-rollback']) {
        await skills.save(
          CharacterSkillState(
            characterId: id,
            skillId: 'climb-old',
            ranks: 3,
            updatedAt: DateTime.utc(2026, 8, 10, 12),
          ),
        );
      }
      skills.close();
      final items = SqliteItemInstanceRepository.open(fixture.path);
      for (final id in <String>['campaign-1', 'campaign-rollback']) {
        await items.save(
          ItemInstance(
            id: 'item-$id',
            campaignId: id,
            definitionId: 'sword-old',
            createdAt: DateTime.utc(2026, 8, 10, 12),
          ),
        );
      }
      items.close();

      final bindings = SqliteCampaignRulesetRepository.open(fixture.path);
      addTearDown(bindings.close);
      for (final id in <String>['campaign-1', 'campaign-rollback']) {
        await bindings.save(
          CampaignRulesetState(
            binding: CampaignRulesetBinding(
              campaignId: id,
              rulesetId: 'rolemaster-rm2',
              rulesetVersion: '1.0.0',
              activeModuleIds: <String>['core'],
              boundAt: DateTime.utc(2026, 8, 10, 13),
            ),
            overlay: CampaignRulesOverlay.clean(
              campaignId: id,
              updatedAt: DateTime.utc(2026, 8, 10, 13),
            ),
          ),
        );
      }

      final legacyCombat = sqlite3.open(fixture.path);
      legacyCombat.execute("""
        INSERT INTO encounters
          (id, campaign_id, name, status, created_at, updated_at, started_at, closed_at)
        VALUES ('enc-closed', 'campaign-1', 'Closed fight', 'closed', 1, 2, 1, 2)
      """);
      legacyCombat.execute("""
        INSERT INTO combat_states
          (encounter_id, campaign_id, ruleset_id, ruleset_version, revision,
           round_number, turn_index, turn_order_json, actions_json, stats_json, conditions_json)
        VALUES ('enc-closed', 'campaign-1', 'rolemaster-rm2', '1.0.0', 2,
                3, 0, '[]', '[]', '{"npc:ogre":{"initiative":-2}}',
                '[{"participantKey":"npc:ogre","conditionId":"stunned","remainingRounds":1,"sourceKey":null}]')
      """);
      legacyCombat.close();

      final migration = MigrateCampaignRuleset(
        campaignRepository: campaigns,
        rulesetRepository: packages,
        campaignRulesetRepository: bindings,
        clock: () => DateTime.utc(2026, 8, 11),
      );
      await migration(
        campaignId: 'campaign-1',
        targetRulesetId: 'rolemaster-rm2',
        targetVersion: '2.0.0',
        expectedSourceVersion: '1.0.0',
        preserveOverlay: false,
        skillIdMappings: const <String, String>{'climb-old': 'climb'},
        itemDefinitionIdMappings: const <String, String>{'sword-old': 'sword'},
      );

      final database = sqlite3.open(fixture.path);
      addTearDown(database.close);
      expect(
        database.select(
          'SELECT skill_id FROM character_skills WHERE character_id = ?',
          <Object?>['character-1'],
        ).single['skill_id'],
        'climb',
      );
      expect(
        database.select(
          'SELECT definition_id FROM item_instances WHERE id = ?',
          <Object?>['item-campaign-1'],
        ).single['definition_id'],
        'sword',
      );
      expect(
        (await bindings.getForCampaign('campaign-1'))!.binding.rulesetVersion,
        '2.0.0',
      );
      expect(
        database.select(
          'SELECT ruleset_version FROM combat_states WHERE encounter_id = ?',
          <Object?>['enc-closed'],
        ).single['ruleset_version'],
        '1.0.0',
      );
      expect(
        database.select(
          'SELECT stats_json FROM combat_states WHERE encounter_id = ?',
          <Object?>['enc-closed'],
        ).single['stats_json'],
        '{"npc:ogre":{"initiative":-2}}',
      );
      expect(
        database.select(
          'SELECT conditions_json FROM combat_states WHERE encounter_id = ?',
          <Object?>['enc-closed'],
        ).single['conditions_json'],
        '[{"participantKey":"npc:ogre","conditionId":"stunned","remainingRounds":1,"sourceKey":null}]',
      );

      await expectLater(
        migration(
          campaignId: 'campaign-rollback',
          targetRulesetId: 'rolemaster-rm2',
          targetVersion: '2.0.0',
          expectedSourceVersion: '1.0.0',
          preserveOverlay: false,
        ),
        throwsStateError,
      );
      database.execute("""
        CREATE TRIGGER fail_campaign_ruleset_migration
        BEFORE UPDATE ON campaign_rulesets
        WHEN OLD.campaign_id = 'campaign-rollback'
        BEGIN
          SELECT RAISE(ABORT, 'forced binding failure');
        END
      """);
      await expectLater(
        migration(
          campaignId: 'campaign-rollback',
          targetRulesetId: 'rolemaster-rm2',
          targetVersion: '2.0.0',
          expectedSourceVersion: '1.0.0',
          preserveOverlay: false,
          skillIdMappings: const <String, String>{'climb-old': 'climb'},
          itemDefinitionIdMappings: const <String, String>{'sword-old': 'sword'},
        ),
        throwsA(isA<SqliteException>()),
      );
      expect(
        database.select(
          'SELECT skill_id FROM character_skills WHERE character_id = ?',
          <Object?>['character-rollback'],
        ).single['skill_id'],
        'climb-old',
      );
      expect(
        database.select(
          'SELECT definition_id FROM item_instances WHERE id = ?',
          <Object?>['item-campaign-rollback'],
        ).single['definition_id'],
        'sword-old',
      );
      expect(
        (await bindings.getForCampaign(
          'campaign-rollback',
        ))!.binding.rulesetVersion,
        '1.0.0',
      );
    });

    test('migrates v9 to v10 without losing creature data', () async {
      final fixture = await _createFixture('ruleset-migration');
      addTearDown(fixture.dispose);
      final creatures = SqliteCreatureRepository.open(fixture.path);
      await creatures.save(
        Creature(
          id: 'creature-1',
          campaignId: 'campaign-1',
          name: 'Lobo',
          createdAt: DateTime.utc(2026, 8, 10, 11),
          metadata: CreatureMetadata(species: 'Lobo'),
        ),
      );
      creatures.close();

      final legacy = sqlite3.open(fixture.path);
      legacy.execute('DROP TABLE encounter_participants');
      legacy.execute('DROP TABLE encounters');
      legacy.execute('DROP TABLE scene_entity_positions');
      legacy.execute('DROP TABLE scene_layers');
      legacy.execute('DROP TABLE scene_maps');
      legacy.execute('DROP TABLE item_instances');
      legacy.execute('DROP TABLE character_skills');
      legacy.execute('DROP TABLE campaign_rulesets');
      legacy.execute('DROP TABLE ruleset_packages');
      legacy.execute('PRAGMA user_version = 9');
      legacy.close();

      final rulesets = SqliteRulesetRepository.open(fixture.path);
      await rulesets.publish(_package());
      rulesets.close();

      final reopenedCreatures = SqliteCreatureRepository.open(fixture.path);
      final creature = await reopenedCreatures.getById('creature-1');
      reopenedCreatures.close();
      final migrated = sqlite3.open(fixture.path);
      final version = migrated.select('PRAGMA user_version').single;
      migrated.close();

      expect(version['user_version'], SqliteRulesetRepository.schemaVersion);
      expect(creature, isNotNull);
      expect(creature!.metadata.species, 'Lobo');
    });
  });
}

RulesetPackage _package({String version = '1.0.0'}) {
  return RulesetPackage(
    manifest: RulesetManifest(
      id: 'rolemaster-rm2',
      systemId: 'rolemaster',
      edition: 'RM2',
      version: version,
      displayName: 'Rolemaster 2nd Edition',
      modules: <RulesetModuleDefinition>[
        RulesetModuleDefinition(id: 'core', name: 'Core', required: true),
        RulesetModuleDefinition(
          id: 'arms-law',
          name: 'Arms Law',
          enabledByDefault: true,
        ),
        RulesetModuleDefinition(id: 'companion-1', name: 'Companion I'),
      ],
      sourceReferences: <String>['Character Law', 'Arms Law'],
    ),
    data: <String, Object?>{
      'skills': <Object?>[
        <String, Object?>{
          'id': version == '1.0.0' ? 'climb-old' : 'climb',
          'name': 'Climb',
          'moduleId': 'core',
          'category': 'Movement',
        },
      ],
      'items': <Object?>[
        <String, Object?>{
          'id': version == '1.0.0' ? 'sword-old' : 'sword',
          'name': 'Sword',
          'moduleId': 'core',
          'category': 'Weapon',
        },
      ],
      'tables': <String, Object?>{
        'critical-e': <String, Object?>{'max': 100},
      },
    },
  );
}

CampaignRulesetState _cleanState({required String version}) {
  return CampaignRulesetState(
    binding: CampaignRulesetBinding(
      campaignId: 'campaign-1',
      rulesetId: 'rolemaster-rm2',
      rulesetVersion: version,
      activeModuleIds: <String>['core'],
      boundAt: DateTime.utc(2026, 8, 10, 12),
    ),
    overlay: CampaignRulesOverlay.clean(
      campaignId: 'campaign-1',
      updatedAt: DateTime.utc(2026, 8, 10, 12),
    ),
  );
}

Future<_Fixture> _createFixture(String prefix) async {
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
  return _Fixture(path: path, directory: directory);
}

final class _Fixture {
  const _Fixture({required this.path, required this.directory});

  final String path;
  final Directory directory;

  Future<void> dispose() => directory.delete(recursive: true);
}

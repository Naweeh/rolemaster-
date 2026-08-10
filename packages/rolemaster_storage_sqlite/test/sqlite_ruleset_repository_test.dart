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
    data: const <String, Object?>{
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

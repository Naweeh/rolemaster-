import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteItemInstanceRepository', () {
    test('persists holder and contained items after reopening', () async {
      final fixture = await _createFixture('item-reopen');
      addTearDown(fixture.dispose);

      final writer = SqliteItemInstanceRepository.open(fixture.path);
      await writer.save(
        ItemInstance(
          id: 'bag',
          campaignId: 'campaign-1',
          definitionId: 'backpack',
          placement: ItemPlacement(
            holder: InventoryHolderRef(
              entityType: 'character',
              entityId: 'character-1',
            ),
          ),
          createdAt: DateTime.utc(2026, 8, 10, 14),
        ),
      );
      await writer.save(
        ItemInstance(
          id: 'sword',
          campaignId: 'campaign-1',
          definitionId: 'longsword',
          quantity: 2,
          placement: ItemPlacement(containerItemId: 'bag'),
          notes: 'Dos hojas gemelas.',
          createdAt: DateTime.utc(2026, 8, 10, 15),
        ),
      );
      writer.close();

      final reader = SqliteItemInstanceRepository.open(fixture.path);
      final bag = await reader.getById('bag');
      final sword = await reader.getById('sword');
      final all = await reader.getForCampaign('campaign-1');
      reader.close();

      expect(bag, isNotNull);
      expect(bag!.placement.holder!.entityType, 'character');
      expect(bag.placement.holder!.entityId, 'character-1');
      expect(sword, isNotNull);
      expect(sword!.quantity, 2);
      expect(sword.placement.containerItemId, 'bag');
      expect(sword.notes, 'Dos hojas gemelas.');
      expect(all.map((item) => item.id), <String>['bag', 'sword']);
    });

    test('upserts transfer and equipment state without duplication', () async {
      final fixture = await _createFixture('item-update');
      addTearDown(fixture.dispose);
      final repository = SqliteItemInstanceRepository.open(fixture.path);
      addTearDown(repository.close);

      final original = ItemInstance(
        id: 'sword',
        campaignId: 'campaign-1',
        definitionId: 'longsword',
        placement: ItemPlacement.unassigned(),
        createdAt: DateTime.utc(2026, 8, 10, 14),
      );
      await repository.save(original);
      await repository.save(
        original.update(
          equipped: true,
          placement: ItemPlacement(
            holder: InventoryHolderRef(
              entityType: 'character',
              entityId: 'character-1',
            ),
          ),
          at: DateTime.utc(2026, 8, 10, 15),
        ),
      );

      final all = await repository.getForCampaign('campaign-1');
      expect(all, hasLength(1));
      expect(all.single.equipped, isTrue);
      expect(all.single.placement.holder!.entityId, 'character-1');
      expect(all.single.createdAt, DateTime.utc(2026, 8, 10, 14));
      expect(all.single.updatedAt, DateTime.utc(2026, 8, 10, 15));
    });

    test('migrates v11 to v12 preserving skills and ruleset binding', () async {
      final fixture = await _createFixture(
        'item-migration',
        withRulesetAndSkill: true,
      );
      addTearDown(fixture.dispose);

      final legacy = sqlite3.open(fixture.path);
      legacy.execute('DROP TABLE encounter_participants');
      legacy.execute('DROP TABLE encounters');
      legacy.execute('DROP TABLE scene_entity_positions');
      legacy.execute('DROP TABLE scene_layers');
      legacy.execute('DROP TABLE scene_maps');
      legacy.execute('DROP TABLE item_instances');
      legacy.execute('PRAGMA user_version = 11');
      legacy.close();

      final items = SqliteItemInstanceRepository.open(fixture.path);
      await items.save(
        ItemInstance(
          id: 'item-1',
          campaignId: 'campaign-1',
          customName: 'Llave oxidada',
          createdAt: DateTime.utc(2026, 8, 10, 16),
        ),
      );
      items.close();

      final skills = SqliteCharacterSkillRepository.open(fixture.path);
      final skill = await skills.getByCharacterAndSkill(
        characterId: 'character-1',
        skillId: 'perception',
      );
      skills.close();

      final campaignRulesets = SqliteCampaignRulesetRepository.open(
        fixture.path,
      );
      final binding = await campaignRulesets.getForCampaign('campaign-1');
      campaignRulesets.close();

      final database = sqlite3.open(fixture.path);
      final version = database.select('PRAGMA user_version').single;
      database.close();

      expect(
        version['user_version'],
        SqliteItemInstanceRepository.schemaVersion,
      );
      expect(skill, isNotNull);
      expect(skill!.ranks, 3);
      expect(binding, isNotNull);
      expect(binding!.binding.rulesetVersion, '0.2.0');
    });

    test('database rejects invalid holder/container combinations', () async {
      final fixture = await _createFixture('item-constraints');
      addTearDown(fixture.dispose);
      final repository = SqliteItemInstanceRepository.open(fixture.path);
      repository.close();

      final database = sqlite3.open(fixture.path);
      addTearDown(database.close);

      expect(
        () => database.execute(
          '''
          INSERT INTO item_instances (
            id,
            campaign_id,
            custom_name,
            quantity,
            equipped,
            holder_entity_type,
            container_item_id,
            created_at,
            updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          <Object?>[
            'invalid',
            'campaign-1',
            'Inválido',
            1,
            0,
            'character',
            'invalid',
            1,
            1,
          ],
        ),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}

Future<_Fixture> _createFixture(
  String prefix, {
  bool withRulesetAndSkill = false,
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

  if (withRulesetAndSkill) {
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

    final skills = SqliteCharacterSkillRepository.open(path);
    await skills.save(
      CharacterSkillState(
        characterId: 'character-1',
        skillId: 'perception',
        ranks: 3,
        updatedAt: DateTime.utc(2026, 8, 10, 13),
      ),
    );
    skills.close();
  }

  return _Fixture(path: path, directory: directory);
}

final class _Fixture {
  const _Fixture({required this.path, required this.directory});

  final String path;
  final Directory directory;

  Future<void> dispose() => directory.delete(recursive: true);
}

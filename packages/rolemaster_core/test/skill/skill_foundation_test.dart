import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  group('Skills', () {
    test('reads immutable skill definitions from ruleset data', () {
      final catalog = RulesetSkillCatalog.fromPackage(_package());

      expect(catalog.definitions, hasLength(3));
      expect(catalog.getById('perception')!.category, 'General');
      expect(
        catalog
            .availableForModules(<String>['core', 'arms-law'])
            .map((skill) => skill.id),
        <String>['perception', 'weapon-blades'],
      );
    });

    test('stores character ranks and named modifiers', () async {
      final fixtures = _Fixtures();
      final setSkill = SetCharacterSkill(
        characterRepository: fixtures.characters,
        rulesetRepository: fixtures.rulesets,
        campaignRulesetRepository: fixtures.campaignRulesets,
        characterSkillRepository: fixtures.skills,
        clock: () => DateTime.utc(2026, 8, 10, 15),
      );

      final state = await setSkill(
        characterId: 'character-1',
        skillId: 'perception',
        ranks: 4,
        modifiers: const <String, int>{'stat': 6, 'profession': 10},
        notes: 'Entrenamiento de frontera',
      );

      expect(state.ranks, 4);
      expect(state.modifierTotal, 16);
      expect(state.notes, 'Entrenamiento de frontera');
      expect(
        await fixtures.skills.getByCharacterAndSkill(
          characterId: 'character-1',
          skillId: 'perception',
        ),
        same(state),
      );
    });

    test('rejects a skill from an inactive ruleset module', () async {
      final fixtures = _Fixtures();
      final setSkill = SetCharacterSkill(
        characterRepository: fixtures.characters,
        rulesetRepository: fixtures.rulesets,
        campaignRulesetRepository: fixtures.campaignRulesets,
        characterSkillRepository: fixtures.skills,
        clock: DateTime.now,
      );

      await expectLater(
        setSkill(
          characterId: 'character-1',
          skillId: 'herb-lore',
          ranks: 1,
        ),
        throwsA(isA<SkillModuleInactiveException>()),
      );
    });

    test('lists active definitions with optional character state', () async {
      final fixtures = _Fixtures();
      await fixtures.skills.save(
        CharacterSkillState(
          characterId: 'character-1',
          skillId: 'perception',
          ranks: 3,
          updatedAt: DateTime.utc(2026, 8, 10, 14),
        ),
      );
      final listSkills = ListCharacterSkills(
        characterRepository: fixtures.characters,
        rulesetRepository: fixtures.rulesets,
        campaignRulesetRepository: fixtures.campaignRulesets,
        characterSkillRepository: fixtures.skills,
      );

      final entries = await listSkills('character-1');

      expect(entries.map((entry) => entry.definition.id), <String>[
        'perception',
        'weapon-blades',
      ]);
      expect(entries.first.state!.ranks, 3);
      expect(entries.last.state, isNull);
    });

    test('rejects duplicate skill ids in a ruleset package', () {
      expect(
        () => RulesetSkillCatalog.fromPackage(
          _package(
            skills: const <Object?>[
              <String, Object?>{'id': 'same', 'name': 'One'},
              <String, Object?>{'id': 'same', 'name': 'Two'},
            ],
          ),
        ),
        throwsA(isA<DuplicateSkillDefinitionException>()),
      );
    });
  });
}

RulesetPackage _package({List<Object?>? skills}) {
  return RulesetPackage(
    manifest: RulesetManifest(
      id: 'rolemaster-demo',
      systemId: 'rolemaster',
      edition: 'Demo',
      version: '0.2.0',
      displayName: 'Rolemaster Demo',
      modules: <RulesetModuleDefinition>[
        RulesetModuleDefinition(id: 'core', name: 'Core', required: true),
        RulesetModuleDefinition(
          id: 'arms-law',
          name: 'Arms Law',
          enabledByDefault: true,
        ),
        RulesetModuleDefinition(id: 'companion-1', name: 'Companion I'),
      ],
    ),
    data: <String, Object?>{
      'skills': skills ??
          const <Object?>[
            <String, Object?>{
              'id': 'perception',
              'name': 'Perception',
              'moduleId': 'core',
              'category': 'General',
              'tags': <String>['awareness'],
            },
            <String, Object?>{
              'id': 'weapon-blades',
              'name': 'Blades',
              'moduleId': 'arms-law',
              'category': 'Combat',
            },
            <String, Object?>{
              'id': 'herb-lore',
              'name': 'Herb Lore',
              'moduleId': 'companion-1',
              'category': 'Lore',
            },
          ],
    },
  );
}

final class _Fixtures {
  _Fixtures() {
    characters = _MemoryCharacterRepository(
      <Character>[
        Character(
          id: 'character-1',
          campaignId: 'campaign-1',
          name: 'Aria',
          createdAt: DateTime.utc(2026, 8, 10, 10),
        ),
      ],
    );
    rulesets = _MemoryRulesetRepository(<RulesetPackage>[_package()]);
    campaignRulesets = _MemoryCampaignRulesetRepository(
      CampaignRulesetState(
        binding: CampaignRulesetBinding(
          campaignId: 'campaign-1',
          rulesetId: 'rolemaster-demo',
          rulesetVersion: '0.2.0',
          activeModuleIds: <String>['core', 'arms-law'],
          boundAt: DateTime.utc(2026, 8, 10, 11),
        ),
        overlay: CampaignRulesOverlay.clean(
          campaignId: 'campaign-1',
          updatedAt: DateTime.utc(2026, 8, 10, 11),
        ),
      ),
    );
    skills = _MemoryCharacterSkillRepository();
  }

  late final _MemoryCharacterRepository characters;
  late final _MemoryRulesetRepository rulesets;
  late final _MemoryCampaignRulesetRepository campaignRulesets;
  late final _MemoryCharacterSkillRepository skills;
}

final class _MemoryCharacterRepository implements CharacterRepository {
  _MemoryCharacterRepository(Iterable<Character> characters) {
    for (final character in characters) {
      _characters[character.id] = character;
    }
  }

  final Map<String, Character> _characters = <String, Character>{};

  @override
  Future<Character?> getById(String id) async => _characters[id];

  @override
  Future<List<Character>> getForCampaign(
    String campaignId, {
    bool includeArchived = false,
  }) async =>
      _characters.values
          .where(
            (character) =>
                character.campaignId == campaignId &&
                (includeArchived || !character.isArchived),
          )
          .toList(growable: false);

  @override
  Future<void> save(Character character) async {
    _characters[character.id] = character;
  }
}

final class _MemoryRulesetRepository implements RulesetRepository {
  _MemoryRulesetRepository(Iterable<RulesetPackage> packages) {
    for (final package in packages) {
      _packages['${package.manifest.id}@${package.manifest.version}'] = package;
    }
  }

  final Map<String, RulesetPackage> _packages = <String, RulesetPackage>{};

  @override
  Future<List<RulesetPackage>> getAvailablePackages() async =>
      List<RulesetPackage>.unmodifiable(_packages.values);

  @override
  Future<RulesetPackage?> getPackage({
    required String rulesetId,
    required String version,
  }) async =>
      _packages['$rulesetId@$version'];
}

final class _MemoryCampaignRulesetRepository
    implements CampaignRulesetRepository {
  _MemoryCampaignRulesetRepository(CampaignRulesetState state) {
    _states[state.binding.campaignId] = state;
  }

  final Map<String, CampaignRulesetState> _states =
      <String, CampaignRulesetState>{};

  @override
  Future<CampaignRulesetState?> getForCampaign(String campaignId) async =>
      _states[campaignId];

  @override
  Future<void> save(CampaignRulesetState state) async {
    _states[state.binding.campaignId] = state;
  }
}

final class _MemoryCharacterSkillRepository
    implements CharacterSkillRepository {
  final Map<String, CharacterSkillState> _states =
      <String, CharacterSkillState>{};

  String _key(String characterId, String skillId) => '$characterId::$skillId';

  @override
  Future<CharacterSkillState?> getByCharacterAndSkill({
    required String characterId,
    required String skillId,
  }) async =>
      _states[_key(characterId, skillId)];

  @override
  Future<List<CharacterSkillState>> getForCharacter(String characterId) async =>
      _states.values
          .where((state) => state.characterId == characterId)
          .toList(growable: false);

  @override
  Future<void> save(CharacterSkillState state) async {
    _states[_key(state.characterId, state.skillId)] = state;
  }
}

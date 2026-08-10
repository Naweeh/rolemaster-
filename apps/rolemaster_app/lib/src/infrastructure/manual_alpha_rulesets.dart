import 'package:rolemaster_core/rolemaster_core.dart';

List<RulesetPackage> buildManualAlphaRulesets() {
  return <RulesetPackage>[_dungeonsAndDragonsBxCompilation()];
}

RulesetPackage _dungeonsAndDragonsBxCompilation() {
  return RulesetPackage(
    manifest: RulesetManifest(
      id: 'dnd-bx-compilation-2024',
      systemId: 'dungeons-and-dragons',
      edition: 'B/X-derived compilation',
      version: '0.1.0-manual-alpha',
      displayName: 'Dungeons & Dragons · B/X Compilation',
      modules: <RulesetModuleDefinition>[
        RulesetModuleDefinition(
          id: 'bx-core',
          name: 'B/X Core',
          required: true,
        ),
        RulesetModuleDefinition(
          id: 'spells',
          name: 'Spells',
          enabledByDefault: true,
        ),
        RulesetModuleDefinition(
          id: 'monsters-treasure',
          name: 'Monsters & Treasure',
          enabledByDefault: true,
        ),
        RulesetModuleDefinition(
          id: 'house-rules-appendix',
          name: 'House Rules / Appendix',
        ),
      ],
      sourceReferences: const <String>[
        'DUNGEONS & DRAGONS.pdf · Drive 187GRO_OjPS2d4Y9-zhugppVVAfxDx2-x',
        'Visual Alpha: structured subset from Character Creation, Character Classes and Equipment.',
      ],
    ),
    data: const <String, Object?>{
      'source': <String, Object?>{
        'fileName': 'DUNGEONS & DRAGONS.pdf',
        'driveFileId': '187GRO_OjPS2d4Y9-zhugppVVAfxDx2-x',
        'pageCount': 215,
        'classification': 'B/X-derived custom compilation',
      },
      'abilities': <Object?>[
        <String, Object?>{'id': 'str', 'name': 'Strength', 'abbr': 'STR'},
        <String, Object?>{'id': 'int', 'name': 'Intelligence', 'abbr': 'INT'},
        <String, Object?>{'id': 'wis', 'name': 'Wisdom', 'abbr': 'WIS'},
        <String, Object?>{'id': 'dex', 'name': 'Dexterity', 'abbr': 'DEX'},
        <String, Object?>{'id': 'con', 'name': 'Constitution', 'abbr': 'CON'},
        <String, Object?>{'id': 'cha', 'name': 'Charisma', 'abbr': 'CHA'},
      ],
      'alignments': <Object?>['Law', 'Neutrality', 'Chaos'],
      'characterCreation': <String, Object?>{
        'startingGold': '3d6 × 10 gp',
        'unarmoredArmorClass': 9,
        'lowerArmorClassIsBetter': true,
      },
      'classes': <Object?>[
        <String, Object?>{
          'id': 'cleric',
          'name': 'Cleric',
          'primeRequisites': <Object?>['WIS'],
          'hitDie': 'd6',
          'armor': 'Any, including shields',
          'weapons': 'Blunt weapons',
        },
        <String, Object?>{
          'id': 'fighter',
          'name': 'Fighter',
          'primeRequisites': <Object?>['STR'],
          'hitDie': 'd8',
          'armor': 'Any, including shields',
          'weapons': 'Any',
        },
        <String, Object?>{
          'id': 'magic-user',
          'name': 'Magic-User',
          'primeRequisites': <Object?>['INT'],
          'hitDie': 'd4',
          'armor': 'None',
          'weapons': 'Dagger',
        },
        <String, Object?>{
          'id': 'thief',
          'name': 'Thief',
          'primeRequisites': <Object?>['DEX'],
          'hitDie': 'd4',
          'armor': 'Leather, no shields',
          'weapons': 'Any',
        },
        <String, Object?>{
          'id': 'dwarf',
          'name': 'Dwarf',
          'primeRequisites': <Object?>['STR'],
          'requirements': <Object?>['CON 9+'],
          'hitDie': 'd8',
          'armor': 'Any, including shields',
          'weapons': 'Any normal-sized weapon',
        },
        <String, Object?>{
          'id': 'elf',
          'name': 'Elf',
          'primeRequisites': <Object?>['STR', 'INT'],
          'requirements': <Object?>['INT 9+'],
          'hitDie': 'd6',
          'armor': 'Any, including shields',
          'weapons': 'Any',
        },
        <String, Object?>{
          'id': 'halfling',
          'name': 'Halfling',
          'primeRequisites': <Object?>['DEX', 'STR'],
          'requirements': <Object?>['CON 9+', 'DEX 9+'],
          'hitDie': 'd6',
          'armor': 'Any small-sized armor, including shields',
          'weapons': 'Any small-sized weapon',
        },
      ],
    },
  );
}

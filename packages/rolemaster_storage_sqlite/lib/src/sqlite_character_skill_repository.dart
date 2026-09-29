import 'dart:convert';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_operation_logger.dart';
import 'sqlite_schema.dart';

final class SqliteCharacterSkillRepository implements CharacterSkillRepository {
  SqliteCharacterSkillRepository._(this._database) {
    initializeRolemasterSqliteSchema(_database);
  }

  factory SqliteCharacterSkillRepository.open(String path) {
    return SqliteCharacterSkillRepository._(sqlite3.open(path));
  }

  factory SqliteCharacterSkillRepository.inMemory() {
    return SqliteCharacterSkillRepository._(sqlite3.openInMemory());
  }

  static const int schemaVersion = rolemasterSqliteSchemaVersion;

  final Database _database;

  @override
  Future<CharacterSkillState?> getByCharacterAndSkill({
    required String characterId,
    required String skillId,
  }) async {
    final rows = _database.loggedSelect(
      '''
      SELECT character_id, skill_id, ranks, modifiers_json, notes, updated_at
      FROM character_skills
      WHERE character_id = ? AND skill_id = ?
      LIMIT 1
      ''',
      <Object?>[characterId.trim(), skillId.trim()],
    );
    return rows.isEmpty ? null : _stateFromRow(rows.single);
  }

  @override
  Future<List<CharacterSkillState>> getForCharacter(String characterId) async {
    final rows = _database.loggedSelect(
      '''
      SELECT character_id, skill_id, ranks, modifiers_json, notes, updated_at
      FROM character_skills
      WHERE character_id = ?
      ORDER BY skill_id
      ''',
      <Object?>[characterId.trim()],
    );
    return rows.map(_stateFromRow).toList(growable: false);
  }

  @override
  Future<void> save(CharacterSkillState state) async {
    _database.loggedExecute(
      '''
      INSERT INTO character_skills (
        character_id,
        skill_id,
        ranks,
        modifiers_json,
        notes,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(character_id, skill_id) DO UPDATE SET
        ranks = excluded.ranks,
        modifiers_json = excluded.modifiers_json,
        notes = excluded.notes,
        updated_at = excluded.updated_at
      ''',
      <Object?>[
        state.characterId,
        state.skillId,
        state.ranks,
        jsonEncode(state.modifiers),
        state.notes,
        state.updatedAt.millisecondsSinceEpoch,
      ],
    );
  }

  void close() {
    _database.close();
  }

  CharacterSkillState _stateFromRow(Row row) {
    final modifiersRaw = jsonDecode(row['modifiers_json'] as String);
    if (modifiersRaw is! Map) {
      throw StateError('Invalid character skill modifiers payload.');
    }
    final modifiers = <String, int>{};
    for (final entry in modifiersRaw.entries) {
      if (entry.key is! String || entry.value is! int) {
        throw StateError('Invalid character skill modifier entry.');
      }
      modifiers[entry.key as String] = entry.value as int;
    }

    return CharacterSkillState(
      characterId: row['character_id'] as String,
      skillId: row['skill_id'] as String,
      ranks: row['ranks'] as int,
      modifiers: modifiers,
      notes: row['notes'] as String?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at'] as int,
        isUtc: true,
      ),
    );
  }
}

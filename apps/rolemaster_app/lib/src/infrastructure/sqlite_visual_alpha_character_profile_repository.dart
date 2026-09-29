import 'dart:convert';

import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';

import '../features/visual_alpha/visual_alpha_character_profile.dart';

final class SqliteVisualAlphaCharacterProfileRepository
    implements VisualAlphaCharacterProfileRepository {
  SqliteVisualAlphaCharacterProfileRepository._(this._database) {
    initializeRolemasterSqliteSchema(_database);
  }

  factory SqliteVisualAlphaCharacterProfileRepository.open(String path) {
    return SqliteVisualAlphaCharacterProfileRepository._(sqlite3.open(path));
  }

  final Database _database;

  @override
  Future<VisualAlphaCharacterProfile?> getForCharacter(
    String characterId,
  ) async {
    final rows = _database.loggedSelect(
      'SELECT * FROM visual_alpha_character_profiles WHERE character_id = ?',
      <Object?>[characterId],
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return VisualAlphaCharacterProfile(
      characterId: row['character_id'] as String,
      rulesetId: row['ruleset_id'] as String,
      rulesetVersion: row['ruleset_version'] as String,
      className: row['class_name'] as String,
      alignment: row['alignment'] as String,
      abilities: Map<String, int>.from(
        jsonDecode(row['abilities_json'] as String) as Map,
      ),
      startingGold: row['starting_gold'] as int,
    );
  }

  @override
  Future<void> save(VisualAlphaCharacterProfile profile) async {
    _database.loggedExecute(
      '''
      INSERT INTO visual_alpha_character_profiles (
        character_id, ruleset_id, ruleset_version, class_name, alignment,
        abilities_json, starting_gold
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(character_id) DO UPDATE SET
        ruleset_id = excluded.ruleset_id,
        ruleset_version = excluded.ruleset_version,
        class_name = excluded.class_name,
        alignment = excluded.alignment,
        abilities_json = excluded.abilities_json,
        starting_gold = excluded.starting_gold
      ''',
      <Object?>[
        profile.characterId,
        profile.rulesetId,
        profile.rulesetVersion,
        profile.className,
        profile.alignment,
        jsonEncode(profile.abilities),
        profile.startingGold,
      ],
    );
  }

  void close() => _database.close();
}

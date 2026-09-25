import 'dart:convert';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_schema.dart';

final class SqliteRulesetRepository
    implements RulesetRepository, RulesetPublisher {
  SqliteRulesetRepository._(this._database) {
    initializeRolemasterSqliteSchema(_database);
  }

  factory SqliteRulesetRepository.open(String path) {
    return SqliteRulesetRepository._(sqlite3.open(path));
  }

  factory SqliteRulesetRepository.inMemory() {
    return SqliteRulesetRepository._(sqlite3.openInMemory());
  }

  static const int schemaVersion = rolemasterSqliteSchemaVersion;

  final Database _database;

  @override
  Future<void> publish(RulesetPackage package) async {
    final manifest = package.manifest;
    final existing = _database.select(
      'SELECT 1 FROM ruleset_packages WHERE ruleset_id = ? AND version = ?',
      <Object?>[manifest.id, manifest.version],
    );
    if (existing.isNotEmpty) {
      throw StateError(
        'Ruleset package ${manifest.id}@${manifest.version} already exists. '
        'Published ruleset versions are immutable.',
      );
    }

    _database.execute(
      '''
      INSERT INTO ruleset_packages (
        ruleset_id,
        version,
        system_id,
        edition,
        display_name,
        modules_json,
        source_references_json,
        data_json
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        manifest.id,
        manifest.version,
        manifest.systemId,
        manifest.edition,
        manifest.displayName,
        jsonEncode(
          manifest.modules
              .map(
                (module) => <String, Object?>{
                  'id': module.id,
                  'name': module.name,
                  'required': module.required,
                  'enabledByDefault': module.enabledByDefault,
                },
              )
              .toList(growable: false),
        ),
        jsonEncode(manifest.sourceReferences),
        jsonEncode(package.data),
      ],
    );
  }

  @override
  Future<RulesetPackage?> getPackage({
    required String rulesetId,
    required String version,
  }) async {
    final rows = _database.select(
      '''
      SELECT
        ruleset_id,
        version,
        system_id,
        edition,
        display_name,
        modules_json,
        source_references_json,
        data_json
      FROM ruleset_packages
      WHERE ruleset_id = ? AND version = ?
      LIMIT 1
      ''',
      <Object?>[rulesetId.trim(), version.trim()],
    );
    return rows.isEmpty ? null : _packageFromRow(rows.single);
  }

  @override
  Future<List<RulesetPackage>> getAvailablePackages() async {
    final rows = _database.select('''
      SELECT
        ruleset_id,
        version,
        system_id,
        edition,
        display_name,
        modules_json,
        source_references_json,
        data_json
      FROM ruleset_packages
      ORDER BY system_id, edition, ruleset_id, version
    ''');
    return rows.map(_packageFromRow).toList(growable: false);
  }

  void close() {
    _database.close();
  }

  RulesetPackage _packageFromRow(Row row) {
    final modulesRaw = jsonDecode(row['modules_json'] as String);
    final referencesRaw = jsonDecode(row['source_references_json'] as String);
    final dataRaw = jsonDecode(row['data_json'] as String);
    if (modulesRaw is! List || referencesRaw is! List || dataRaw is! Map) {
      throw StateError(
        'Invalid ruleset package payload in Rolemaster database.',
      );
    }

    return RulesetPackage(
      manifest: RulesetManifest(
        id: row['ruleset_id'] as String,
        systemId: row['system_id'] as String,
        edition: row['edition'] as String,
        version: row['version'] as String,
        displayName: row['display_name'] as String,
        modules: modulesRaw.map((value) {
          if (value is! Map<String, Object?>) {
            throw StateError('Invalid ruleset module payload.');
          }
          return RulesetModuleDefinition(
            id: value['id']! as String,
            name: value['name']! as String,
            required: value['required']! as bool,
            enabledByDefault: value['enabledByDefault']! as bool,
          );
        }),
        sourceReferences: referencesRaw.cast<String>(),
      ),
      data: Map<String, Object?>.from(dataRaw),
    );
  }
}

final class SqliteCampaignRulesetRepository
    implements CampaignRulesetRepository {
  SqliteCampaignRulesetRepository._(this._database) {
    initializeRolemasterSqliteSchema(_database);
  }

  factory SqliteCampaignRulesetRepository.open(String path) {
    return SqliteCampaignRulesetRepository._(sqlite3.open(path));
  }

  factory SqliteCampaignRulesetRepository.inMemory() {
    return SqliteCampaignRulesetRepository._(sqlite3.openInMemory());
  }

  static const int schemaVersion = rolemasterSqliteSchemaVersion;

  final Database _database;

  @override
  Future<CampaignRulesetState?> getForCampaign(String campaignId) async {
    final rows = _database.select(
      '''
      SELECT
        campaign_id,
        ruleset_id,
        ruleset_version,
        active_module_ids_json,
        bound_at,
        overlay_json,
        overlay_updated_at
      FROM campaign_rulesets
      WHERE campaign_id = ?
      LIMIT 1
      ''',
      <Object?>[campaignId.trim()],
    );
    if (rows.isEmpty) {
      return null;
    }

    final row = rows.single;
    final modulesRaw = jsonDecode(row['active_module_ids_json'] as String);
    final overlayRaw = jsonDecode(row['overlay_json'] as String);
    if (modulesRaw is! List || overlayRaw is! Map) {
      throw StateError(
        'Invalid campaign ruleset payload in Rolemaster database.',
      );
    }

    return CampaignRulesetState(
      binding: CampaignRulesetBinding(
        campaignId: row['campaign_id'] as String,
        rulesetId: row['ruleset_id'] as String,
        rulesetVersion: row['ruleset_version'] as String,
        activeModuleIds: modulesRaw.cast<String>(),
        boundAt: DateTime.fromMillisecondsSinceEpoch(
          row['bound_at'] as int,
          isUtc: true,
        ),
      ),
      overlay: CampaignRulesOverlay(
        campaignId: row['campaign_id'] as String,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          row['overlay_updated_at'] as int,
          isUtc: true,
        ),
        overrides: Map<String, Object?>.from(overlayRaw),
      ),
    );
  }

  @override
  Future<void> save(CampaignRulesetState state) async {
    final current = await getForCampaign(state.binding.campaignId);
    if (current != null &&
        (current.binding.rulesetId != state.binding.rulesetId ||
            current.binding.rulesetVersion != state.binding.rulesetVersion)) {
      throw StateError(
        'Changing a campaign ruleset version requires a controlled migration.',
      );
    }

    _database.execute(
      '''
      INSERT INTO campaign_rulesets (
        campaign_id,
        ruleset_id,
        ruleset_version,
        active_module_ids_json,
        bound_at,
        overlay_json,
        overlay_updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(campaign_id) DO UPDATE SET
        active_module_ids_json = excluded.active_module_ids_json,
        overlay_json = excluded.overlay_json,
        overlay_updated_at = excluded.overlay_updated_at
      ''',
      <Object?>[
        state.binding.campaignId,
        state.binding.rulesetId,
        state.binding.rulesetVersion,
        jsonEncode(state.binding.activeModuleIds),
        state.binding.boundAt.millisecondsSinceEpoch,
        jsonEncode(state.overlay.overrides),
        state.overlay.updatedAt.millisecondsSinceEpoch,
      ],
    );
  }

  @override
  Future<void> migrate({
    required CampaignRulesetState expected,
    required CampaignRulesetState next,
  }) async {
    if (expected.binding.campaignId != next.binding.campaignId ||
        expected.binding.rulesetId != next.binding.rulesetId ||
        expected.binding.rulesetVersion == next.binding.rulesetVersion) {
      throw StateError('Invalid campaign ruleset migration.');
    }
    _database.execute('BEGIN IMMEDIATE');
    try {
      final active = _database.select(
        "SELECT 1 FROM encounters WHERE campaign_id = ? AND status = 'active' LIMIT 1",
        <Object?>[expected.binding.campaignId],
      );
      if (active.isNotEmpty) {
        throw StateError('Close active encounters before migrating rulesets.');
      }
      final target = _database.select(
        'SELECT 1 FROM ruleset_packages WHERE ruleset_id = ? AND version = ?',
        <Object?>[next.binding.rulesetId, next.binding.rulesetVersion],
      );
      if (target.isEmpty) {
        throw StateError('Target ruleset package is not published.');
      }
      final changed = _database.select(
        '''UPDATE campaign_rulesets
           SET ruleset_version = ?, active_module_ids_json = ?,
               bound_at = ?, overlay_json = ?, overlay_updated_at = ?
           WHERE campaign_id = ? AND ruleset_id = ?
             AND ruleset_version = ? AND bound_at = ?
             AND overlay_updated_at = ?
           RETURNING campaign_id''',
        <Object?>[
          next.binding.rulesetVersion,
          jsonEncode(next.binding.activeModuleIds),
          next.binding.boundAt.millisecondsSinceEpoch,
          jsonEncode(next.overlay.overrides),
          next.overlay.updatedAt.millisecondsSinceEpoch,
          expected.binding.campaignId,
          expected.binding.rulesetId,
          expected.binding.rulesetVersion,
          expected.binding.boundAt.millisecondsSinceEpoch,
          expected.overlay.updatedAt.millisecondsSinceEpoch,
        ],
      );
      if (changed.length != 1) {
        throw StateError('Campaign ruleset changed during migration.');
      }
      _database.execute('COMMIT');
    } catch (_) {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }

  void close() {
    _database.close();
  }
}

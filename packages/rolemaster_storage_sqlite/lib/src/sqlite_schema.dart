import 'package:sqlite3/sqlite3.dart';

const int rolemasterSqliteSchemaVersion = 14;

void initializeRolemasterSqliteSchema(Database database) {
  database.execute('PRAGMA foreign_keys = ON');

  var version = _readSchemaVersion(database);
  if (version < 0 || version > rolemasterSqliteSchemaVersion) {
    throw StateError(
      'Unsupported Rolemaster database schema: $version. '
      'Expected <= $rolemasterSqliteSchemaVersion.',
    );
  }

  if (version == 0) {
    _runMigration(
      database,
      targetVersion: 2,
      migrate: () {
        _createCampaignSchemaV2(database);
      },
    );
    version = 2;
  } else if (version == 1) {
    _runMigration(
      database,
      targetVersion: 2,
      migrate: () {
        _migrateCampaignV1ToV2(database);
      },
    );
    version = 2;
  }

  if (version == 2) {
    _runMigration(
      database,
      targetVersion: 3,
      migrate: () {
        _createWorldSchemaV3(database);
      },
    );
    version = 3;
  }

  if (version == 3) {
    _runMigration(
      database,
      targetVersion: 4,
      migrate: () {
        _createCalendarSchemaV4(database);
      },
    );
    version = 4;
  }

  if (version == 4) {
    _runMigration(
      database,
      targetVersion: 5,
      migrate: () {
        _createEventSchemaV5(database);
      },
    );
    version = 5;
  }

  if (version == 5) {
    _runMigration(
      database,
      targetVersion: 6,
      migrate: () {
        _createCampaignStateSchemaV6(database);
      },
    );
    version = 6;
  }

  if (version == 6) {
    _runMigration(
      database,
      targetVersion: 7,
      migrate: () {
        _createCharacterSchemaV7(database);
      },
    );
    version = 7;
  }

  if (version == 7) {
    _runMigration(
      database,
      targetVersion: 8,
      migrate: () {
        _createNpcSchemaV8(database);
      },
    );
    version = 8;
  }

  if (version == 8) {
    _runMigration(
      database,
      targetVersion: 9,
      migrate: () {
        _createCreatureSchemaV9(database);
      },
    );
    version = 9;
  }

  if (version == 9) {
    _runMigration(
      database,
      targetVersion: 10,
      migrate: () {
        _createRulesetSchemaV10(database);
      },
    );
    version = 10;
  }

  if (version == 10) {
    _runMigration(
      database,
      targetVersion: 11,
      migrate: () {
        _createCharacterSkillSchemaV11(database);
      },
    );
    version = 11;
  }

  if (version == 11) {
    _runMigration(
      database,
      targetVersion: 12,
      migrate: () {
        _createItemInstanceSchemaV12(database);
      },
    );
    version = 12;
  }

  if (version == 12) {
    _runMigration(
      database,
      targetVersion: 13,
      migrate: () {
        _createSceneMapSchemaV13(database);
      },
    );
    version = 13;
  }

  if (version == 13) {
    _runMigration(
      database,
      targetVersion: 14,
      migrate: () {
        _createEncounterSchemaV14(database);
      },
    );
    version = 14;
  }

  if (version != rolemasterSqliteSchemaVersion) {
    throw StateError(
      'Rolemaster database migration stopped at schema $version; '
      'expected $rolemasterSqliteSchemaVersion.',
    );
  }
}

int _readSchemaVersion(Database database) {
  final rows = database.select('PRAGMA user_version');
  return rows.single['user_version'] as int;
}

void _runMigration(
  Database database, {
  required int targetVersion,
  required void Function() migrate,
}) {
  database.execute('BEGIN IMMEDIATE');
  try {
    migrate();
    database.execute('PRAGMA user_version = $targetVersion');
    database.execute('COMMIT');
  } catch (_) {
    database.execute('ROLLBACK');
    rethrow;
  }
}

void _createCampaignSchemaV2(Database database) {
  database.execute('''
    CREATE TABLE campaigns (
      id TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      archived_at INTEGER,
      description TEXT,
      tags_json TEXT NOT NULL DEFAULT '[]',
      ai_enabled INTEGER NOT NULL DEFAULT 1 CHECK (ai_enabled IN (0, 1)),
      voice_enabled INTEGER NOT NULL DEFAULT 1 CHECK (voice_enabled IN (0, 1)),
      audio_enabled INTEGER NOT NULL DEFAULT 1 CHECK (audio_enabled IN (0, 1))
    ) STRICT
  ''');
}

void _migrateCampaignV1ToV2(Database database) {
  database.execute('ALTER TABLE campaigns ADD COLUMN description TEXT');
  database.execute(
    "ALTER TABLE campaigns ADD COLUMN tags_json TEXT NOT NULL DEFAULT '[]'",
  );
  database.execute(
    'ALTER TABLE campaigns ADD COLUMN ai_enabled INTEGER NOT NULL '
    'DEFAULT 1 CHECK (ai_enabled IN (0, 1))',
  );
  database.execute(
    'ALTER TABLE campaigns ADD COLUMN voice_enabled INTEGER NOT NULL '
    'DEFAULT 1 CHECK (voice_enabled IN (0, 1))',
  );
  database.execute(
    'ALTER TABLE campaigns ADD COLUMN audio_enabled INTEGER NOT NULL '
    'DEFAULT 1 CHECK (audio_enabled IN (0, 1))',
  );
}

void _createWorldSchemaV3(Database database) {
  database.execute('''
    CREATE TABLE worlds (
      id TEXT NOT NULL PRIMARY KEY,
      campaign_id TEXT NOT NULL,
      name TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      description TEXT,
      tags_json TEXT NOT NULL DEFAULT '[]',
      FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE RESTRICT
    ) STRICT
  ''');
  database.execute(
    'CREATE INDEX idx_worlds_campaign_id ON worlds(campaign_id)',
  );

  database.execute('''
    CREATE TABLE regions (
      id TEXT NOT NULL PRIMARY KEY,
      world_id TEXT NOT NULL,
      name TEXT NOT NULL,
      parent_region_id TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      description TEXT,
      tags_json TEXT NOT NULL DEFAULT '[]',
      FOREIGN KEY (world_id) REFERENCES worlds(id) ON DELETE CASCADE,
      FOREIGN KEY (parent_region_id) REFERENCES regions(id) ON DELETE RESTRICT
    ) STRICT
  ''');
  database.execute('CREATE INDEX idx_regions_world_id ON regions(world_id)');
  database.execute(
    'CREATE INDEX idx_regions_parent_id ON regions(parent_region_id)',
  );

  database.execute('''
    CREATE TABLE locations (
      id TEXT NOT NULL PRIMARY KEY,
      world_id TEXT NOT NULL,
      name TEXT NOT NULL,
      region_id TEXT,
      parent_location_id TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      description TEXT,
      tags_json TEXT NOT NULL DEFAULT '[]',
      FOREIGN KEY (world_id) REFERENCES worlds(id) ON DELETE CASCADE,
      FOREIGN KEY (region_id) REFERENCES regions(id) ON DELETE RESTRICT,
      FOREIGN KEY (parent_location_id) REFERENCES locations(id) ON DELETE RESTRICT
    ) STRICT
  ''');
  database.execute(
    'CREATE INDEX idx_locations_world_id ON locations(world_id)',
  );
  database.execute(
    'CREATE INDEX idx_locations_region_id ON locations(region_id)',
  );
  database.execute(
    'CREATE INDEX idx_locations_parent_id ON locations(parent_location_id)',
  );
}

void _createCalendarSchemaV4(Database database) {
  database.execute('''
    CREATE TABLE calendars (
      id TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      months_json TEXT NOT NULL,
      weekdays_json TEXT NOT NULL,
      hours_per_day INTEGER NOT NULL CHECK (hours_per_day > 0),
      minutes_per_hour INTEGER NOT NULL CHECK (minutes_per_hour > 0),
      starting_weekday_index INTEGER NOT NULL CHECK (starting_weekday_index >= 0)
    ) STRICT
  ''');

  database.execute('''
    CREATE TABLE campaign_timelines (
      campaign_id TEXT NOT NULL PRIMARY KEY,
      calendar_id TEXT NOT NULL,
      current_year INTEGER NOT NULL CHECK (current_year >= 1),
      current_month INTEGER NOT NULL CHECK (current_month >= 1),
      current_day INTEGER NOT NULL CHECK (current_day >= 1),
      current_hour INTEGER NOT NULL CHECK (current_hour >= 0),
      current_minute INTEGER NOT NULL CHECK (current_minute >= 0),
      FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE CASCADE,
      FOREIGN KEY (calendar_id) REFERENCES calendars(id) ON DELETE RESTRICT
    ) STRICT
  ''');
  database.execute(
    'CREATE INDEX idx_campaign_timelines_calendar_id '
    'ON campaign_timelines(calendar_id)',
  );

  database.execute('''
    CREATE TABLE temporal_events (
      id TEXT NOT NULL PRIMARY KEY,
      campaign_id TEXT NOT NULL,
      calendar_id TEXT NOT NULL,
      title TEXT NOT NULL,
      scheduled_year INTEGER NOT NULL CHECK (scheduled_year >= 1),
      scheduled_month INTEGER NOT NULL CHECK (scheduled_month >= 1),
      scheduled_day INTEGER NOT NULL CHECK (scheduled_day >= 1),
      scheduled_hour INTEGER NOT NULL CHECK (scheduled_hour >= 0),
      scheduled_minute INTEGER NOT NULL CHECK (scheduled_minute >= 0),
      notes TEXT,
      FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE CASCADE,
      FOREIGN KEY (calendar_id) REFERENCES calendars(id) ON DELETE RESTRICT
    ) STRICT
  ''');
  database.execute(
    'CREATE INDEX idx_temporal_events_campaign_id '
    'ON temporal_events(campaign_id)',
  );
  database.execute(
    'CREATE INDEX idx_temporal_events_calendar_id '
    'ON temporal_events(calendar_id)',
  );
}

void _createEventSchemaV5(Database database) {
  database.execute('''
    CREATE TABLE domain_events (
      sequence INTEGER PRIMARY KEY AUTOINCREMENT,
      id TEXT NOT NULL UNIQUE,
      type TEXT NOT NULL,
      campaign_id TEXT NOT NULL,
      occurred_at INTEGER NOT NULL,
      entity_type TEXT,
      entity_id TEXT,
      payload_json TEXT NOT NULL,
      FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE CASCADE
    ) STRICT
  ''');
  database.execute(
    'CREATE INDEX idx_domain_events_campaign_sequence '
    'ON domain_events(campaign_id, sequence)',
  );
  database.execute(
    'CREATE INDEX idx_domain_events_campaign_type_sequence '
    'ON domain_events(campaign_id, type, sequence)',
  );
  database.execute(
    'CREATE INDEX idx_domain_events_type ON domain_events(type)',
  );
}

void _createCampaignStateSchemaV6(Database database) {
  database.execute('''
    CREATE TABLE campaign_states (
      campaign_id TEXT NOT NULL PRIMARY KEY,
      revision INTEGER NOT NULL CHECK (revision > 0),
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE CASCADE
    ) STRICT
  ''');
}

void _createCharacterSchemaV7(Database database) {
  database.execute('''
    CREATE TABLE characters (
      id TEXT NOT NULL PRIMARY KEY,
      campaign_id TEXT NOT NULL,
      name TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      archived_at INTEGER,
      player_name TEXT,
      description TEXT,
      notes TEXT,
      tags_json TEXT NOT NULL DEFAULT '[]',
      FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE CASCADE
    ) STRICT
  ''');
  database.execute(
    'CREATE INDEX idx_characters_campaign_archived '
    'ON characters(campaign_id, archived_at)',
  );
}

void _createNpcSchemaV8(Database database) {
  database.execute('''
    CREATE TABLE npcs (
      id TEXT NOT NULL PRIMARY KEY,
      campaign_id TEXT NOT NULL,
      name TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      archived_at INTEGER,
      world_id TEXT,
      location_id TEXT,
      native_language TEXT NOT NULL,
      known_languages_json TEXT NOT NULL DEFAULT '[]',
      role TEXT,
      description TEXT,
      notes TEXT,
      tags_json TEXT NOT NULL DEFAULT '[]',
      CHECK (location_id IS NULL OR world_id IS NOT NULL),
      FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE CASCADE,
      FOREIGN KEY (world_id) REFERENCES worlds(id) ON DELETE SET NULL,
      FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE SET NULL
    ) STRICT
  ''');
  database.execute(
    'CREATE INDEX idx_npcs_campaign_archived '
    'ON npcs(campaign_id, archived_at)',
  );
  database.execute(
    'CREATE INDEX idx_npcs_world_location ON npcs(world_id, location_id)',
  );
}

void _createCreatureSchemaV9(Database database) {
  database.execute('''
    CREATE TABLE creatures (
      id TEXT NOT NULL PRIMARY KEY,
      campaign_id TEXT NOT NULL,
      name TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      archived_at INTEGER,
      world_id TEXT,
      location_id TEXT,
      species TEXT NOT NULL,
      category TEXT,
      description TEXT,
      notes TEXT,
      tags_json TEXT NOT NULL DEFAULT '[]',
      CHECK (location_id IS NULL OR world_id IS NOT NULL),
      FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE CASCADE,
      FOREIGN KEY (world_id) REFERENCES worlds(id) ON DELETE SET NULL,
      FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE SET NULL
    ) STRICT
  ''');
  database.execute(
    'CREATE INDEX idx_creatures_campaign_archived '
    'ON creatures(campaign_id, archived_at)',
  );
  database.execute(
    'CREATE INDEX idx_creatures_world_location '
    'ON creatures(world_id, location_id)',
  );
}

void _createRulesetSchemaV10(Database database) {
  database.execute('''
    CREATE TABLE ruleset_packages (
      ruleset_id TEXT NOT NULL,
      version TEXT NOT NULL,
      system_id TEXT NOT NULL,
      edition TEXT NOT NULL,
      display_name TEXT NOT NULL,
      modules_json TEXT NOT NULL,
      source_references_json TEXT NOT NULL,
      data_json TEXT NOT NULL,
      PRIMARY KEY (ruleset_id, version)
    ) STRICT
  ''');
  database.execute(
    'CREATE INDEX idx_ruleset_packages_system_edition '
    'ON ruleset_packages(system_id, edition)',
  );

  database.execute('''
    CREATE TABLE campaign_rulesets (
      campaign_id TEXT NOT NULL PRIMARY KEY,
      ruleset_id TEXT NOT NULL,
      ruleset_version TEXT NOT NULL,
      active_module_ids_json TEXT NOT NULL,
      bound_at INTEGER NOT NULL,
      overlay_json TEXT NOT NULL DEFAULT '{}',
      overlay_updated_at INTEGER NOT NULL,
      FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE CASCADE,
      FOREIGN KEY (ruleset_id, ruleset_version)
        REFERENCES ruleset_packages(ruleset_id, version) ON DELETE RESTRICT
    ) STRICT
  ''');
  database.execute(
    'CREATE INDEX idx_campaign_rulesets_package '
    'ON campaign_rulesets(ruleset_id, ruleset_version)',
  );
}

void _createCharacterSkillSchemaV11(Database database) {
  database.execute('''
    CREATE TABLE character_skills (
      character_id TEXT NOT NULL,
      skill_id TEXT NOT NULL,
      ranks INTEGER NOT NULL CHECK (ranks >= 0),
      modifiers_json TEXT NOT NULL DEFAULT '{}',
      notes TEXT,
      updated_at INTEGER NOT NULL,
      PRIMARY KEY (character_id, skill_id),
      FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE
    ) STRICT
  ''');
  database.execute(
    'CREATE INDEX idx_character_skills_character '
    'ON character_skills(character_id)',
  );
}

void _createItemInstanceSchemaV12(Database database) {
  database.execute('''
    CREATE TABLE item_instances (
      id TEXT NOT NULL PRIMARY KEY,
      campaign_id TEXT NOT NULL,
      definition_id TEXT,
      custom_name TEXT,
      quantity INTEGER NOT NULL CHECK (quantity > 0),
      equipped INTEGER NOT NULL DEFAULT 0 CHECK (equipped IN (0, 1)),
      holder_entity_type TEXT,
      holder_entity_id TEXT,
      container_item_id TEXT,
      notes TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      CHECK (definition_id IS NOT NULL OR custom_name IS NOT NULL),
      CHECK (
        (holder_entity_type IS NULL AND holder_entity_id IS NULL) OR
        (holder_entity_type IS NOT NULL AND holder_entity_id IS NOT NULL)
      ),
      CHECK (
        container_item_id IS NULL OR
        (holder_entity_type IS NULL AND holder_entity_id IS NULL)
      ),
      CHECK (container_item_id IS NULL OR container_item_id <> id),
      FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE CASCADE,
      FOREIGN KEY (container_item_id) REFERENCES item_instances(id) ON DELETE RESTRICT
    ) STRICT
  ''');
  database.execute(
    'CREATE INDEX idx_item_instances_campaign '
    'ON item_instances(campaign_id, created_at, id)',
  );
  database.execute(
    'CREATE INDEX idx_item_instances_holder '
    'ON item_instances(holder_entity_type, holder_entity_id)',
  );
  database.execute(
    'CREATE INDEX idx_item_instances_container '
    'ON item_instances(container_item_id)',
  );
}

void _createSceneMapSchemaV13(Database database) {
  database.execute('''
    CREATE TABLE scene_maps (
      id TEXT NOT NULL PRIMARY KEY,
      campaign_id TEXT NOT NULL,
      name TEXT NOT NULL,
      world_id TEXT,
      location_id TEXT,
      logical_width REAL NOT NULL CHECK (logical_width > 0),
      logical_height REAL NOT NULL CHECK (logical_height > 0),
      notes TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      CHECK (location_id IS NULL OR world_id IS NOT NULL),
      FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE CASCADE,
      FOREIGN KEY (world_id) REFERENCES worlds(id) ON DELETE SET NULL,
      FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE SET NULL
    ) STRICT
  ''');
  database.execute(
    'CREATE INDEX idx_scene_maps_campaign ON scene_maps(campaign_id, created_at, id)',
  );
  database.execute(
    'CREATE INDEX idx_scene_maps_world_location ON scene_maps(world_id, location_id)',
  );

  database.execute('''
    CREATE TABLE scene_layers (
      id TEXT NOT NULL PRIMARY KEY,
      scene_map_id TEXT NOT NULL,
      name TEXT NOT NULL,
      order_index INTEGER NOT NULL CHECK (order_index >= 0),
      visibility TEXT NOT NULL CHECK (visibility IN ('gmOnly', 'shared')),
      UNIQUE (scene_map_id, order_index),
      UNIQUE (scene_map_id, id),
      FOREIGN KEY (scene_map_id) REFERENCES scene_maps(id) ON DELETE CASCADE
    ) STRICT
  ''');
  database.execute(
    'CREATE INDEX idx_scene_layers_map_order '
    'ON scene_layers(scene_map_id, order_index)',
  );

  database.execute('''
    CREATE TABLE scene_entity_positions (
      scene_map_id TEXT NOT NULL,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      x REAL NOT NULL,
      y REAL NOT NULL,
      layer_id TEXT,
      updated_at INTEGER NOT NULL,
      PRIMARY KEY (scene_map_id, entity_type, entity_id),
      FOREIGN KEY (scene_map_id) REFERENCES scene_maps(id) ON DELETE CASCADE,
      FOREIGN KEY (scene_map_id, layer_id)
        REFERENCES scene_layers(scene_map_id, id) ON DELETE SET NULL
    ) STRICT
  ''');
  database.execute(
    'CREATE INDEX idx_scene_positions_map_layer '
    'ON scene_entity_positions(scene_map_id, layer_id)',
  );
}

void _createEncounterSchemaV14(Database database) {
  database.execute('''
    CREATE TABLE encounters (
      id TEXT NOT NULL PRIMARY KEY,
      campaign_id TEXT NOT NULL,
      name TEXT NOT NULL,
      status TEXT NOT NULL CHECK (status IN ('planned', 'active', 'closed')),
      world_id TEXT,
      location_id TEXT,
      scene_map_id TEXT,
      notes TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      started_at INTEGER,
      closed_at INTEGER,
      CHECK (location_id IS NULL OR world_id IS NOT NULL),
      CHECK (
        (status = 'planned' AND started_at IS NULL AND closed_at IS NULL) OR
        (status = 'active' AND started_at IS NOT NULL AND closed_at IS NULL) OR
        (status = 'closed' AND started_at IS NOT NULL AND closed_at IS NOT NULL)
      ),
      CHECK (closed_at IS NULL OR closed_at >= started_at),
      FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE CASCADE,
      FOREIGN KEY (world_id) REFERENCES worlds(id) ON DELETE SET NULL,
      FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE SET NULL,
      FOREIGN KEY (scene_map_id) REFERENCES scene_maps(id) ON DELETE SET NULL
    ) STRICT
  ''');
  database.execute(
    'CREATE INDEX idx_encounters_campaign_status '
    'ON encounters(campaign_id, status, created_at, id)',
  );
  database.execute(
    'CREATE INDEX idx_encounters_context '
    'ON encounters(world_id, location_id, scene_map_id)',
  );

  database.execute('''
    CREATE TABLE encounter_participants (
      encounter_id TEXT NOT NULL,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      label TEXT,
      PRIMARY KEY (encounter_id, entity_type, entity_id),
      FOREIGN KEY (encounter_id) REFERENCES encounters(id) ON DELETE CASCADE
    ) STRICT
  ''');
  database.execute(
    'CREATE INDEX idx_encounter_participants_entity '
    'ON encounter_participants(entity_type, entity_id)',
  );
}

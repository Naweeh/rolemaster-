import 'package:sqlite3/sqlite3.dart';

const int rolemasterSqliteSchemaVersion = 5;

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

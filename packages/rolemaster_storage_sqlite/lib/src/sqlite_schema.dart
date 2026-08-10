import 'package:sqlite3/sqlite3.dart';

const int rolemasterSqliteSchemaVersion = 3;

void initializeRolemasterSqliteSchema(Database database) {
  database.execute('PRAGMA foreign_keys = ON');

  final versionRows = database.select('PRAGMA user_version');
  final version = versionRows.single['user_version'] as int;

  switch (version) {
    case 0:
      _runMigration(database, () {
        _createCampaignSchemaV2(database);
        _createWorldSchemaV3(database);
      });
    case 1:
      _runMigration(database, () {
        _migrateCampaignV1ToV2(database);
        _createWorldSchemaV3(database);
      });
    case 2:
      _runMigration(database, () {
        _createWorldSchemaV3(database);
      });
    case rolemasterSqliteSchemaVersion:
      return;
    default:
      throw StateError(
        'Unsupported Rolemaster database schema: $version. '
        'Expected <= $rolemasterSqliteSchemaVersion.',
      );
  }
}

void _runMigration(Database database, void Function() migrate) {
  database.execute('BEGIN IMMEDIATE');
  try {
    migrate();
    database.execute('PRAGMA user_version = $rolemasterSqliteSchemaVersion');
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

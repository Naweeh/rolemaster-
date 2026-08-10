import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'sqlite_schema.dart';

final class SqliteSnapshotInfo {
  const SqliteSnapshotInfo({
    required this.path,
    required this.createdAt,
    required this.schemaVersion,
    required this.sizeBytes,
  });

  final String path;
  final DateTime createdAt;
  final int schemaVersion;
  final int sizeBytes;
}

final class SqliteRestoreResult {
  const SqliteRestoreResult({
    required this.destinationPath,
    required this.schemaVersion,
    this.rollbackPath,
  });

  final String destinationPath;
  final int schemaVersion;
  final String? rollbackPath;
}

final class SqliteSnapshotException implements Exception {
  SqliteSnapshotException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() {
    final detail = cause == null ? '' : ' Cause: $cause';
    return 'SqliteSnapshotException: $message$detail';
  }
}

final class SqliteSnapshotService {
  const SqliteSnapshotService();

  Future<SqliteSnapshotInfo> createSnapshot({
    required String sourcePath,
    required String snapshotPath,
  }) async {
    final source = File(sourcePath).absolute;
    final snapshot = File(snapshotPath).absolute;

    if (source.path == snapshot.path) {
      throw ArgumentError('Snapshot path must differ from source database.');
    }
    if (!await source.exists()) {
      throw SqliteSnapshotException(
        'Source Rolemaster database does not exist: ${source.path}',
      );
    }
    if (await snapshot.exists()) {
      throw SqliteSnapshotException(
        'Snapshot already exists and will not be overwritten: ${snapshot.path}',
      );
    }

    await snapshot.parent.create(recursive: true);
    try {
      await _copyDatabase(
        sourcePath: source.path,
        destinationPath: snapshot.path,
        migrateSource: true,
        migrateDestination: false,
      );
      return await validateSnapshot(snapshot.path, requireCurrentSchema: true);
    } catch (error) {
      await _deleteDatabaseFiles(snapshot.path);
      if (error is SqliteSnapshotException) {
        rethrow;
      }
      throw SqliteSnapshotException(
        'Could not create Rolemaster snapshot.',
        cause: error,
      );
    }
  }

  Future<SqliteSnapshotInfo> validateSnapshot(
    String snapshotPath, {
    bool requireCurrentSchema = false,
  }) async {
    final snapshot = File(snapshotPath).absolute;
    if (!await snapshot.exists()) {
      throw SqliteSnapshotException(
        'Snapshot does not exist: ${snapshot.path}',
      );
    }

    Database? database;
    try {
      database = sqlite3.open(snapshot.path, mode: OpenMode.readOnly);
      final schemaVersion = _verifyRolemasterDatabase(
        database,
        requireCurrentSchema: requireCurrentSchema,
      );
      database.close();
      database = null;

      return SqliteSnapshotInfo(
        path: snapshot.path,
        createdAt: (await snapshot.lastModified()).toUtc(),
        schemaVersion: schemaVersion,
        sizeBytes: await snapshot.length(),
      );
    } catch (error) {
      if (error is SqliteSnapshotException) {
        rethrow;
      }
      throw SqliteSnapshotException(
        'Invalid Rolemaster snapshot: ${snapshot.path}',
        cause: error,
      );
    } finally {
      database?.close();
    }
  }

  Future<SqliteRestoreResult> restoreSnapshot({
    required String snapshotPath,
    required String destinationPath,
    String? rollbackPath,
  }) async {
    final snapshot = File(snapshotPath).absolute;
    final destination = File(destinationPath).absolute;

    if (snapshot.path == destination.path) {
      throw ArgumentError(
        'Snapshot path must differ from destination database.',
      );
    }

    await validateSnapshot(snapshot.path);

    String? rollbackSnapshotPath;
    if (await destination.exists()) {
      rollbackSnapshotPath = rollbackPath == null
          ? await _availableRollbackPath(destination.path)
          : File(rollbackPath).absolute.path;
      if (rollbackSnapshotPath == snapshot.path ||
          rollbackSnapshotPath == destination.path) {
        throw ArgumentError(
          'Rollback path must differ from snapshot and destination.',
        );
      }
      await createSnapshot(
        sourcePath: destination.path,
        snapshotPath: rollbackSnapshotPath,
      );
    }

    await destination.parent.create(recursive: true);
    await _deleteDatabaseFiles(destination.path);

    try {
      await _copyDatabase(
        sourcePath: snapshot.path,
        destinationPath: destination.path,
        migrateSource: false,
        migrateDestination: true,
      );
      final restored = await validateSnapshot(
        destination.path,
        requireCurrentSchema: true,
      );
      return SqliteRestoreResult(
        destinationPath: destination.path,
        schemaVersion: restored.schemaVersion,
        rollbackPath: rollbackSnapshotPath,
      );
    } catch (restoreError) {
      await _deleteDatabaseFiles(destination.path);
      if (rollbackSnapshotPath != null) {
        try {
          await _copyDatabase(
            sourcePath: rollbackSnapshotPath,
            destinationPath: destination.path,
            migrateSource: false,
            migrateDestination: true,
          );
        } catch (rollbackError) {
          throw SqliteSnapshotException(
            'Snapshot restore failed and the automatic rollback also failed.',
            cause: <Object>[restoreError, rollbackError],
          );
        }
      }
      throw SqliteSnapshotException(
        'Snapshot restore failed. Original database was preserved in rollback.',
        cause: restoreError,
      );
    }
  }

  Future<void> _copyDatabase({
    required String sourcePath,
    required String destinationPath,
    required bool migrateSource,
    required bool migrateDestination,
  }) async {
    Database? source;
    Database? destination;
    try {
      source = sqlite3.open(
        sourcePath,
        mode: migrateSource ? OpenMode.readWrite : OpenMode.readOnly,
      );
      if (migrateSource) {
        initializeRolemasterSqliteSchema(source);
      } else {
        _verifyRolemasterDatabase(source);
      }

      destination = sqlite3.open(destinationPath);
      await source.backup(destination).drain();

      if (migrateDestination) {
        initializeRolemasterSqliteSchema(destination);
      }
      _verifyRolemasterDatabase(
        destination,
        requireCurrentSchema: migrateSource || migrateDestination,
      );
    } finally {
      destination?.close();
      source?.close();
    }
  }

  int _verifyRolemasterDatabase(
    Database database, {
    bool requireCurrentSchema = false,
  }) {
    final version = database.userVersion;
    if (version <= 0 || version > rolemasterSqliteSchemaVersion) {
      throw SqliteSnapshotException(
        'Unsupported Rolemaster snapshot schema: $version.',
      );
    }
    if (requireCurrentSchema && version != rolemasterSqliteSchemaVersion) {
      throw SqliteSnapshotException(
        'Expected current Rolemaster schema $rolemasterSqliteSchemaVersion, '
        'found $version.',
      );
    }

    final campaignsTable = database.select(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' AND name = 'campaigns'",
    );
    if (campaignsTable.length != 1) {
      throw SqliteSnapshotException(
        'Snapshot is missing the Rolemaster campaigns table.',
      );
    }

    final integrity = database.select('PRAGMA integrity_check');
    if (integrity.length != 1 || integrity.single['integrity_check'] != 'ok') {
      throw SqliteSnapshotException('SQLite integrity_check failed.');
    }

    final foreignKeyFailures = database.select('PRAGMA foreign_key_check');
    if (foreignKeyFailures.isNotEmpty) {
      throw SqliteSnapshotException(
        'SQLite foreign_key_check found ${foreignKeyFailures.length} failures.',
      );
    }

    return version;
  }

  Future<String> _availableRollbackPath(String destinationPath) async {
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    var candidate = '$destinationPath.pre-restore-$timestamp.snapshot';
    var suffix = 1;
    while (await File(candidate).exists()) {
      candidate = '$destinationPath.pre-restore-$timestamp-$suffix.snapshot';
      suffix += 1;
    }
    return candidate;
  }

  Future<void> _deleteDatabaseFiles(String databasePath) async {
    for (final path in <String>[
      databasePath,
      '$databasePath-wal',
      '$databasePath-shm',
    ]) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}

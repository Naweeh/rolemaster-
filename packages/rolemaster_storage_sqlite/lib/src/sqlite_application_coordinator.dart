import 'dart:io';

import 'sqlite_snapshot_service.dart';

/// Owns the SQLite repositories opened by one application session.
///
/// Open every file-backed repository through [openRepository] so a restore can
/// close its live connections before replacing the database. Repositories
/// opened outside this coordinator are not managed by it.
final class SqliteApplicationCoordinator {
  SqliteApplicationCoordinator({SqliteSnapshotService? snapshotService})
    : _snapshotService = snapshotService ?? const SqliteSnapshotService();

  final SqliteSnapshotService _snapshotService;
  final Map<String, Set<ManagedSqliteRepository<Object>>> _open = {};
  bool _restoring = false;

  ManagedSqliteRepository<T> openRepository<T extends Object>({
    required String databasePath,
    required T Function(String path) open,
    required void Function(T repository) close,
  }) {
    if (_restoring) {
      throw StateError('Cannot open a database during snapshot restore.');
    }
    final path = File(databasePath).absolute.path;
    final repository = open(path);
    late final ManagedSqliteRepository<T> handle;
    handle = ManagedSqliteRepository<T>._(repository, () {
      close(repository);
      _open[path]?.remove(handle);
      if (_open[path]?.isEmpty ?? false) _open.remove(path);
    });
    _open.putIfAbsent(path, () => {}).add(handle);
    return handle;
  }

  Future<SqliteRestoreResult> restoreSnapshot({
    required String snapshotPath,
    required String destinationPath,
    String? rollbackPath,
  }) async {
    if (_restoring) {
      throw StateError('A snapshot restore is already in progress.');
    }
    _restoring = true;
    try {
      return await _snapshotService.restoreSnapshot(
        snapshotPath: snapshotPath,
        destinationPath: destinationPath,
        rollbackPath: rollbackPath,
        closeDestinationConnections: (path) async {
          for (final handle in List<ManagedSqliteRepository<Object>>.of(
            _open[path] ?? <ManagedSqliteRepository<Object>>{},
          )) {
            handle.close();
          }
        },
      );
    } finally {
      _restoring = false;
    }
  }
}

/// A repository handle whose lifetime is controlled by its coordinator.
final class ManagedSqliteRepository<T extends Object> {
  ManagedSqliteRepository._(this.repository, this._close);

  final T repository;
  final void Function() _close;
  bool _closed = false;

  bool get isClosed => _closed;

  void close() {
    if (_closed) return;
    _close();
    _closed = true;
  }
}

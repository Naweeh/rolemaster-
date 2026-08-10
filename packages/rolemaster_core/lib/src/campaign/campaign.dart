final class Campaign {
  Campaign({
    required String id,
    required String name,
    required DateTime createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
  }) : id = id.trim(),
       name = name.trim(),
       createdAt = createdAt.toUtc(),
       updatedAt = (updatedAt ?? createdAt).toUtc(),
       archivedAt = archivedAt?.toUtc() {
    if (this.id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Campaign id cannot be empty.');
    }
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Campaign name cannot be empty.');
    }
    if (this.updatedAt.isBefore(this.createdAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'Campaign updatedAt cannot be before createdAt.',
      );
    }
    if (this.archivedAt != null && this.archivedAt!.isBefore(this.createdAt)) {
      throw ArgumentError.value(
        archivedAt,
        'archivedAt',
        'Campaign archivedAt cannot be before createdAt.',
      );
    }
  }

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  Campaign rename({required String name, required DateTime at}) {
    if (isArchived) {
      throw StateError('Archived campaigns cannot be renamed.');
    }

    final normalizedAt = at.toUtc();
    if (normalizedAt.isBefore(updatedAt)) {
      throw ArgumentError.value(
        at,
        'at',
        'Campaign changes cannot move backwards in time.',
      );
    }

    return Campaign(
      id: id,
      name: name,
      createdAt: createdAt,
      updatedAt: normalizedAt,
    );
  }

  Campaign archive({required DateTime at}) {
    if (isArchived) {
      return this;
    }

    final normalizedAt = at.toUtc();
    if (normalizedAt.isBefore(updatedAt)) {
      throw ArgumentError.value(
        at,
        'at',
        'Campaign changes cannot move backwards in time.',
      );
    }

    return Campaign(
      id: id,
      name: name,
      createdAt: createdAt,
      updatedAt: normalizedAt,
      archivedAt: normalizedAt,
    );
  }
}

import 'character_metadata.dart';

final class Character {
  Character({
    required String id,
    required String campaignId,
    required String name,
    required DateTime createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
    CharacterMetadata? metadata,
  })  : id = id.trim(),
        campaignId = campaignId.trim(),
        name = name.trim(),
        createdAt = createdAt.toUtc(),
        updatedAt = (updatedAt ?? createdAt).toUtc(),
        archivedAt = archivedAt?.toUtc(),
        metadata = metadata ?? CharacterMetadata() {
    if (this.id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Character id cannot be empty.');
    }
    if (this.campaignId.isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'Character campaignId cannot be empty.',
      );
    }
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Character name cannot be empty.');
    }
    if (this.updatedAt.isBefore(this.createdAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'Character updatedAt cannot be before createdAt.',
      );
    }
    if (this.archivedAt != null && this.archivedAt!.isBefore(this.createdAt)) {
      throw ArgumentError.value(
        archivedAt,
        'archivedAt',
        'Character archivedAt cannot be before createdAt.',
      );
    }
  }

  final String id;
  final String campaignId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final CharacterMetadata metadata;

  bool get isArchived => archivedAt != null;

  Character update({
    String? name,
    CharacterMetadata? metadata,
    required DateTime at,
  }) {
    if (isArchived) {
      throw StateError('Archived characters cannot be updated.');
    }
    if (name == null && metadata == null) {
      throw ArgumentError(
        'At least one Character field must be provided for update.',
      );
    }

    final normalizedAt = at.toUtc();
    if (normalizedAt.isBefore(updatedAt)) {
      throw ArgumentError.value(
        at,
        'at',
        'Character changes cannot move backwards in time.',
      );
    }

    return Character(
      id: id,
      campaignId: campaignId,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: normalizedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Character archive({required DateTime at}) {
    if (isArchived) {
      return this;
    }

    final normalizedAt = at.toUtc();
    if (normalizedAt.isBefore(updatedAt)) {
      throw ArgumentError.value(
        at,
        'at',
        'Character changes cannot move backwards in time.',
      );
    }

    return Character(
      id: id,
      campaignId: campaignId,
      name: name,
      createdAt: createdAt,
      updatedAt: normalizedAt,
      archivedAt: normalizedAt,
      metadata: metadata,
    );
  }
}

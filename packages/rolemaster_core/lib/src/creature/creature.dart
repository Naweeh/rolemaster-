import 'creature_metadata.dart';
import 'creature_placement.dart';

final class Creature {
  Creature({
    required String id,
    required String campaignId,
    required String name,
    required DateTime createdAt,
    required CreatureMetadata metadata,
    DateTime? updatedAt,
    DateTime? archivedAt,
    CreaturePlacement? placement,
  })  : id = id.trim(),
        campaignId = campaignId.trim(),
        name = name.trim(),
        createdAt = createdAt.toUtc(),
        updatedAt = (updatedAt ?? createdAt).toUtc(),
        archivedAt = archivedAt?.toUtc(),
        metadata = metadata,
        placement = placement ?? CreaturePlacement.unplaced() {
    if (this.id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Creature id cannot be empty.');
    }
    if (this.campaignId.isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'Creature campaignId cannot be empty.',
      );
    }
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Creature name cannot be empty.');
    }
    if (this.updatedAt.isBefore(this.createdAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'Creature updatedAt cannot be before createdAt.',
      );
    }
    if (this.archivedAt != null && this.archivedAt!.isBefore(this.createdAt)) {
      throw ArgumentError.value(
        archivedAt,
        'archivedAt',
        'Creature archivedAt cannot be before createdAt.',
      );
    }
  }

  final String id;
  final String campaignId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final CreatureMetadata metadata;
  final CreaturePlacement placement;

  bool get isArchived => archivedAt != null;

  Creature update({
    String? name,
    CreatureMetadata? metadata,
    CreaturePlacement? placement,
    required DateTime at,
  }) {
    if (isArchived) {
      throw StateError('Archived creatures cannot be updated.');
    }
    if (name == null && metadata == null && placement == null) {
      throw ArgumentError(
        'At least one Creature field must be provided for update.',
      );
    }

    final normalizedAt = at.toUtc();
    if (normalizedAt.isBefore(updatedAt)) {
      throw ArgumentError.value(
        at,
        'at',
        'Creature changes cannot move backwards in time.',
      );
    }

    return Creature(
      id: id,
      campaignId: campaignId,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: normalizedAt,
      metadata: metadata ?? this.metadata,
      placement: placement ?? this.placement,
    );
  }

  Creature archive({required DateTime at}) {
    if (isArchived) {
      return this;
    }

    final normalizedAt = at.toUtc();
    if (normalizedAt.isBefore(updatedAt)) {
      throw ArgumentError.value(
        at,
        'at',
        'Creature changes cannot move backwards in time.',
      );
    }

    return Creature(
      id: id,
      campaignId: campaignId,
      name: name,
      createdAt: createdAt,
      updatedAt: normalizedAt,
      archivedAt: normalizedAt,
      metadata: metadata,
      placement: placement,
    );
  }
}

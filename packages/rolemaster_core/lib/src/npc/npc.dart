import 'npc_metadata.dart';
import 'npc_placement.dart';

final class Npc {
  Npc({
    required String id,
    required String campaignId,
    required String name,
    required DateTime createdAt,
    required NpcMetadata metadata,
    DateTime? updatedAt,
    DateTime? archivedAt,
    NpcPlacement? placement,
  })  : id = id.trim(),
        campaignId = campaignId.trim(),
        name = name.trim(),
        createdAt = createdAt.toUtc(),
        updatedAt = (updatedAt ?? createdAt).toUtc(),
        archivedAt = archivedAt?.toUtc(),
        metadata = metadata,
        placement = placement ?? NpcPlacement.unplaced() {
    if (this.id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'NPC id cannot be empty.');
    }
    if (this.campaignId.isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'NPC campaignId cannot be empty.',
      );
    }
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'NPC name cannot be empty.');
    }
    if (this.updatedAt.isBefore(this.createdAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'NPC updatedAt cannot be before createdAt.',
      );
    }
    if (this.archivedAt != null && this.archivedAt!.isBefore(this.createdAt)) {
      throw ArgumentError.value(
        archivedAt,
        'archivedAt',
        'NPC archivedAt cannot be before createdAt.',
      );
    }
  }

  final String id;
  final String campaignId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final NpcMetadata metadata;
  final NpcPlacement placement;

  bool get isArchived => archivedAt != null;

  Npc update({
    String? name,
    NpcMetadata? metadata,
    NpcPlacement? placement,
    required DateTime at,
  }) {
    if (isArchived) {
      throw StateError('Archived NPCs cannot be updated.');
    }
    if (name == null && metadata == null && placement == null) {
      throw ArgumentError(
        'At least one NPC field must be provided for update.',
      );
    }

    final normalizedAt = at.toUtc();
    if (normalizedAt.isBefore(updatedAt)) {
      throw ArgumentError.value(
        at,
        'at',
        'NPC changes cannot move backwards in time.',
      );
    }

    return Npc(
      id: id,
      campaignId: campaignId,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: normalizedAt,
      metadata: metadata ?? this.metadata,
      placement: placement ?? this.placement,
    );
  }

  Npc archive({required DateTime at}) {
    if (isArchived) {
      return this;
    }

    final normalizedAt = at.toUtc();
    if (normalizedAt.isBefore(updatedAt)) {
      throw ArgumentError.value(
        at,
        'at',
        'NPC changes cannot move backwards in time.',
      );
    }

    return Npc(
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

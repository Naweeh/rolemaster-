import 'world_metadata.dart';

final class World {
  World({
    required String id,
    required String campaignId,
    required String name,
    required DateTime createdAt,
    DateTime? updatedAt,
    WorldMetadata? metadata,
  })  : id = id.trim(),
        campaignId = campaignId.trim(),
        name = name.trim(),
        createdAt = createdAt.toUtc(),
        updatedAt = (updatedAt ?? createdAt).toUtc(),
        metadata = metadata ?? WorldMetadata() {
    if (this.id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'World id cannot be empty.');
    }
    if (this.campaignId.isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'World campaignId cannot be empty.',
      );
    }
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'World name cannot be empty.');
    }
    if (this.updatedAt.isBefore(this.createdAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'World updatedAt cannot be before createdAt.',
      );
    }
  }

  final String id;
  final String campaignId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final WorldMetadata metadata;

  World update({
    String? name,
    WorldMetadata? metadata,
    required DateTime at,
  }) {
    if (name == null && metadata == null) {
      throw ArgumentError('At least one World field must be provided for update.');
    }

    final normalizedAt = at.toUtc();
    if (normalizedAt.isBefore(updatedAt)) {
      throw ArgumentError.value(
        at,
        'at',
        'World changes cannot move backwards in time.',
      );
    }

    return World(
      id: id,
      campaignId: campaignId,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: normalizedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

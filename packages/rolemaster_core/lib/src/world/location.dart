import 'world_metadata.dart';

final class Location {
  Location({
    required String id,
    required String worldId,
    required String name,
    String? regionId,
    String? parentLocationId,
    required DateTime createdAt,
    DateTime? updatedAt,
    WorldMetadata? metadata,
  })  : id = id.trim(),
        worldId = worldId.trim(),
        name = name.trim(),
        regionId = _normalizeOptionalId(regionId),
        parentLocationId = _normalizeOptionalId(parentLocationId),
        createdAt = createdAt.toUtc(),
        updatedAt = (updatedAt ?? createdAt).toUtc(),
        metadata = metadata ?? WorldMetadata() {
    if (this.id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Location id cannot be empty.');
    }
    if (this.worldId.isEmpty) {
      throw ArgumentError.value(
        worldId,
        'worldId',
        'Location worldId cannot be empty.',
      );
    }
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Location name cannot be empty.');
    }
    if (this.parentLocationId == this.id) {
      throw ArgumentError.value(
        parentLocationId,
        'parentLocationId',
        'Location cannot be its own parent.',
      );
    }
    if (this.updatedAt.isBefore(this.createdAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'Location updatedAt cannot be before createdAt.',
      );
    }
  }

  final String id;
  final String worldId;
  final String name;
  final String? regionId;
  final String? parentLocationId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final WorldMetadata metadata;

  static String? _normalizeOptionalId(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

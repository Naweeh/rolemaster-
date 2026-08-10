import 'world_metadata.dart';

final class Region {
  Region({
    required String id,
    required String worldId,
    required String name,
    String? parentRegionId,
    required DateTime createdAt,
    DateTime? updatedAt,
    WorldMetadata? metadata,
  })  : id = id.trim(),
        worldId = worldId.trim(),
        name = name.trim(),
        parentRegionId = _normalizeOptionalId(parentRegionId),
        createdAt = createdAt.toUtc(),
        updatedAt = (updatedAt ?? createdAt).toUtc(),
        metadata = metadata ?? WorldMetadata() {
    if (this.id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Region id cannot be empty.');
    }
    if (this.worldId.isEmpty) {
      throw ArgumentError.value(
        worldId,
        'worldId',
        'Region worldId cannot be empty.',
      );
    }
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Region name cannot be empty.');
    }
    if (this.parentRegionId == this.id) {
      throw ArgumentError.value(
        parentRegionId,
        'parentRegionId',
        'Region cannot be its own parent.',
      );
    }
    if (this.updatedAt.isBefore(this.createdAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'Region updatedAt cannot be before createdAt.',
      );
    }
  }

  final String id;
  final String worldId;
  final String name;
  final String? parentRegionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final WorldMetadata metadata;

  static String? _normalizeOptionalId(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

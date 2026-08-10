import 'scene_coordinate_space.dart';

final class SceneMap {
  SceneMap({
    required String id,
    required String campaignId,
    required String name,
    String? worldId,
    String? locationId,
    required SceneCoordinateSpace coordinateSpace,
    String? notes,
    required DateTime createdAt,
    DateTime? updatedAt,
  })  : id = _required(id, 'id'),
        campaignId = _required(campaignId, 'campaignId'),
        name = _required(name, 'name'),
        worldId = _optional(worldId),
        locationId = _optional(locationId),
        coordinateSpace = coordinateSpace,
        notes = _optional(notes),
        createdAt = createdAt.toUtc(),
        updatedAt = (updatedAt ?? createdAt).toUtc() {
    if (this.locationId != null && this.worldId == null) {
      throw ArgumentError('A map location requires worldId.');
    }
    if (this.updatedAt.isBefore(this.createdAt)) {
      throw ArgumentError('updatedAt cannot be before createdAt.');
    }
  }

  final String id;
  final String campaignId;
  final String name;
  final String? worldId;
  final String? locationId;
  final SceneCoordinateSpace coordinateSpace;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, '$field cannot be empty.');
  }
  return normalized;
}

String? _optional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

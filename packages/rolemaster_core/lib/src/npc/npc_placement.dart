final class NpcPlacement {
  NpcPlacement({String? worldId, String? locationId})
      : worldId = _normalizeOptionalId(worldId),
        locationId = _normalizeOptionalId(locationId) {
    if (this.locationId != null && this.worldId == null) {
      throw ArgumentError(
        'NPC location requires a worldId.',
      );
    }
  }

  factory NpcPlacement.unplaced() => NpcPlacement();

  final String? worldId;
  final String? locationId;

  bool get isPlaced => worldId != null;

  static String? _normalizeOptionalId(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

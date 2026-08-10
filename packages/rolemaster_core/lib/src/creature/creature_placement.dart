final class CreaturePlacement {
  CreaturePlacement({String? worldId, String? locationId})
      : worldId = _normalizeOptionalId(worldId),
        locationId = _normalizeOptionalId(locationId) {
    if (this.locationId != null && this.worldId == null) {
      throw ArgumentError('Creature location requires a worldId.');
    }
  }

  factory CreaturePlacement.unplaced() => CreaturePlacement();

  final String? worldId;
  final String? locationId;

  bool get isPlaced => worldId != null;

  static String? _normalizeOptionalId(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

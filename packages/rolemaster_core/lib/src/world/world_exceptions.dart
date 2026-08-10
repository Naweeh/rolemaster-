final class WorldNotFoundException implements Exception {
  WorldNotFoundException(this.worldId);

  final String worldId;

  @override
  String toString() => 'World not found: $worldId';
}

final class RegionNotFoundException implements Exception {
  RegionNotFoundException(this.regionId);

  final String regionId;

  @override
  String toString() => 'Region not found: $regionId';
}

final class LocationNotFoundException implements Exception {
  LocationNotFoundException(this.locationId);

  final String locationId;

  @override
  String toString() => 'Location not found: $locationId';
}

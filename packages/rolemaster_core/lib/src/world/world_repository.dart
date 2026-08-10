import 'location.dart';
import 'region.dart';
import 'world.dart';

abstract interface class WorldRepository {
  Future<World?> getWorldById(String id);

  Future<List<World>> getWorldsForCampaign(String campaignId);

  Future<void> saveWorld(World world);

  Future<Region?> getRegionById(String id);

  Future<List<Region>> getRegionsForWorld(String worldId);

  Future<void> saveRegion(Region region);

  Future<Location?> getLocationById(String id);

  Future<List<Location>> getLocationsForWorld(String worldId);

  Future<void> saveLocation(Location location);
}

import '../world/world_exceptions.dart';
import '../world/world_repository.dart';
import 'creature_placement.dart';

Future<void> validateCreaturePlacement({
  required CreaturePlacement placement,
  required String campaignId,
  required WorldRepository worldRepository,
}) async {
  final worldId = placement.worldId;
  if (worldId == null) {
    return;
  }

  final world = await worldRepository.getWorldById(worldId);
  if (world == null) {
    throw WorldNotFoundException(worldId);
  }
  if (world.campaignId != campaignId) {
    throw StateError('Creature world must belong to the same campaign.');
  }

  final locationId = placement.locationId;
  if (locationId == null) {
    return;
  }
  final location = await worldRepository.getLocationById(locationId);
  if (location == null) {
    throw LocationNotFoundException(locationId);
  }
  if (location.worldId != worldId) {
    throw StateError('Creature location must belong to the selected world.');
  }
}

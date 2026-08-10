import 'location.dart';
import 'world_exceptions.dart';
import 'world_metadata.dart';
import 'world_repository.dart';
import 'world_support.dart';

final class AddLocation {
  AddLocation({
    required WorldRepository repository,
    required WorldEntityIdGenerator idGenerator,
    required WorldClock clock,
  })  : _repository = repository,
        _idGenerator = idGenerator,
        _clock = clock;

  final WorldRepository _repository;
  final WorldEntityIdGenerator _idGenerator;
  final WorldClock _clock;

  Future<Location> call({
    required String worldId,
    required String name,
    String? regionId,
    String? parentLocationId,
    WorldMetadata? metadata,
  }) async {
    final normalizedWorldId = worldId.trim();
    final world = await _repository.getWorldById(normalizedWorldId);
    if (world == null) {
      throw WorldNotFoundException(normalizedWorldId);
    }

    var effectiveRegionId = _normalizeOptionalId(regionId);
    if (effectiveRegionId != null) {
      final region = await _repository.getRegionById(effectiveRegionId);
      if (region == null) {
        throw RegionNotFoundException(effectiveRegionId);
      }
      if (region.worldId != normalizedWorldId) {
        throw StateError('Location region must belong to the same world.');
      }
    }

    final normalizedParentId = _normalizeOptionalId(parentLocationId);
    if (normalizedParentId != null) {
      final parent = await _repository.getLocationById(normalizedParentId);
      if (parent == null) {
        throw LocationNotFoundException(normalizedParentId);
      }
      if (parent.worldId != normalizedWorldId) {
        throw StateError('Parent location must belong to the same world.');
      }
      if (parent.regionId != null) {
        if (effectiveRegionId == null) {
          effectiveRegionId = parent.regionId;
        } else if (effectiveRegionId != parent.regionId) {
          throw StateError(
            'Child location cannot belong to a different region than its parent.',
          );
        }
      }
    }

    final now = _clock().toUtc();
    final location = Location(
      id: _idGenerator(),
      worldId: normalizedWorldId,
      name: name,
      regionId: effectiveRegionId,
      parentLocationId: normalizedParentId,
      createdAt: now,
      updatedAt: now,
      metadata: metadata,
    );
    await _repository.saveLocation(location);
    return location;
  }

  String? _normalizeOptionalId(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

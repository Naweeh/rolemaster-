import 'region.dart';
import 'world_exceptions.dart';
import 'world_metadata.dart';
import 'world_repository.dart';
import 'world_support.dart';

final class AddRegion {
  AddRegion({
    required WorldRepository repository,
    required WorldEntityIdGenerator idGenerator,
    required WorldClock clock,
  })  : _repository = repository,
        _idGenerator = idGenerator,
        _clock = clock;

  final WorldRepository _repository;
  final WorldEntityIdGenerator _idGenerator;
  final WorldClock _clock;

  Future<Region> call({
    required String worldId,
    required String name,
    String? parentRegionId,
    WorldMetadata? metadata,
  }) async {
    final normalizedWorldId = worldId.trim();
    final world = await _repository.getWorldById(normalizedWorldId);
    if (world == null) {
      throw WorldNotFoundException(normalizedWorldId);
    }

    final normalizedParentId = _normalizeOptionalId(parentRegionId);
    if (normalizedParentId != null) {
      final parent = await _repository.getRegionById(normalizedParentId);
      if (parent == null) {
        throw RegionNotFoundException(normalizedParentId);
      }
      if (parent.worldId != normalizedWorldId) {
        throw StateError('Parent region must belong to the same world.');
      }
    }

    final now = _clock().toUtc();
    final region = Region(
      id: _idGenerator(),
      worldId: normalizedWorldId,
      name: name,
      parentRegionId: normalizedParentId,
      createdAt: now,
      updatedAt: now,
      metadata: metadata,
    );
    await _repository.saveRegion(region);
    return region;
  }

  String? _normalizeOptionalId(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

import 'inventory_exceptions.dart';
import 'item_instance.dart';
import 'item_instance_repository.dart';
import 'item_placement.dart';

typedef TransferClock = DateTime Function();

final class TransferItemInstance {
  TransferItemInstance({
    required ItemInstanceRepository repository,
    required TransferClock clock,
  })  : _repository = repository,
        _clock = clock;

  final ItemInstanceRepository _repository;
  final TransferClock _clock;

  Future<ItemInstance> call({
    required String itemId,
    required ItemPlacement placement,
    bool? equipped,
  }) async {
    final item = await _repository.getById(itemId);
    if (item == null) {
      throw ItemInstanceNotFoundException(itemId);
    }

    await _validatePlacement(item, placement);
    final nextEquipped = placement.isContained || placement.isUnassigned
        ? false
        : equipped ?? item.equipped;
    final updated = item.update(
      placement: placement,
      equipped: nextEquipped,
      at: _clock(),
    );
    await _repository.save(updated);
    return updated;
  }

  Future<void> _validatePlacement(
    ItemInstance item,
    ItemPlacement placement,
  ) async {
    final containerId = placement.containerItemId;
    if (containerId == null) {
      return;
    }
    if (containerId == item.id) {
      throw ItemContainmentCycleException(item.id, containerId);
    }

    var currentId = containerId;
    final visited = <String>{};
    while (true) {
      if (!visited.add(currentId)) {
        throw ItemContainmentCycleException(item.id, containerId);
      }
      final current = await _repository.getById(currentId);
      if (current == null) {
        throw ItemInstanceNotFoundException(currentId);
      }
      if (current.campaignId != item.campaignId) {
        throw CrossCampaignItemContainerException(item.id, containerId);
      }
      if (current.id == item.id) {
        throw ItemContainmentCycleException(item.id, containerId);
      }
      final parentId = current.placement.containerItemId;
      if (parentId == null) {
        return;
      }
      currentId = parentId;
    }
  }
}

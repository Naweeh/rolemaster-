final class InventoryHolderRef {
  InventoryHolderRef({
    required String entityType,
    required String entityId,
  })  : entityType = _required(entityType, 'entityType'),
        entityId = _required(entityId, 'entityId');

  final String entityType;
  final String entityId;
}

final class ItemPlacement {
  ItemPlacement({
    InventoryHolderRef? holder,
    String? containerItemId,
  })  : holder = holder,
        containerItemId = _optional(containerItemId) {
    if (holder != null && this.containerItemId != null) {
      throw ArgumentError(
        'An item cannot have a direct holder and a container at the same time.',
      );
    }
  }

  factory ItemPlacement.unassigned() => ItemPlacement();

  final InventoryHolderRef? holder;
  final String? containerItemId;

  bool get isUnassigned => holder == null && containerItemId == null;
  bool get isContained => containerItemId != null;
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

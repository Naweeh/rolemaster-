import 'item_placement.dart';

final class ItemInstance {
  ItemInstance({
    required String id,
    required String campaignId,
    String? definitionId,
    String? customName,
    int quantity = 1,
    bool equipped = false,
    ItemPlacement? placement,
    String? notes,
    required DateTime createdAt,
    DateTime? updatedAt,
  })  : id = _required(id, 'id'),
        campaignId = _required(campaignId, 'campaignId'),
        definitionId = _optional(definitionId),
        customName = _optional(customName),
        quantity = quantity,
        equipped = equipped,
        placement = placement ?? ItemPlacement.unassigned(),
        notes = _optional(notes),
        createdAt = createdAt.toUtc(),
        updatedAt = (updatedAt ?? createdAt).toUtc() {
    if (this.definitionId == null && this.customName == null) {
      throw ArgumentError(
        'A custom item requires customName when definitionId is absent.',
      );
    }
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Quantity must be positive.');
    }
    if (this.updatedAt.isBefore(this.createdAt)) {
      throw ArgumentError('updatedAt cannot be before createdAt.');
    }
    if (this.placement.containerItemId == this.id) {
      throw ArgumentError('An item cannot contain itself.');
    }
  }

  final String id;
  final String campaignId;
  final String? definitionId;
  final String? customName;
  final int quantity;
  final bool equipped;
  final ItemPlacement placement;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCustom => definitionId == null;

  ItemInstance update({
    int? quantity,
    bool? equipped,
    ItemPlacement? placement,
    String? notes,
    bool clearNotes = false,
    required DateTime at,
  }) {
    final normalizedAt = at.toUtc();
    if (normalizedAt.isBefore(updatedAt)) {
      throw ArgumentError.value(
        at,
        'at',
        'Item changes cannot move backwards in time.',
      );
    }

    return ItemInstance(
      id: id,
      campaignId: campaignId,
      definitionId: definitionId,
      customName: customName,
      quantity: quantity ?? this.quantity,
      equipped: equipped ?? this.equipped,
      placement: placement ?? this.placement,
      notes: clearNotes ? null : notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: normalizedAt,
    );
  }
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

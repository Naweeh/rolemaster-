import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_schema.dart';

final class SqliteItemInstanceRepository implements ItemInstanceRepository {
  SqliteItemInstanceRepository._(this._database) {
    initializeRolemasterSqliteSchema(_database);
  }

  factory SqliteItemInstanceRepository.open(String path) {
    return SqliteItemInstanceRepository._(sqlite3.open(path));
  }

  factory SqliteItemInstanceRepository.inMemory() {
    return SqliteItemInstanceRepository._(sqlite3.openInMemory());
  }

  static const int schemaVersion = rolemasterSqliteSchemaVersion;

  final Database _database;

  @override
  Future<ItemInstance?> getById(String id) async {
    final rows = _database.select(
      '''
      SELECT
        id,
        campaign_id,
        definition_id,
        custom_name,
        quantity,
        equipped,
        holder_entity_type,
        holder_entity_id,
        container_item_id,
        notes,
        created_at,
        updated_at
      FROM item_instances
      WHERE id = ?
      LIMIT 1
      ''',
      <Object?>[id.trim()],
    );
    return rows.isEmpty ? null : _itemFromRow(rows.single);
  }

  @override
  Future<List<ItemInstance>> getForCampaign(String campaignId) async {
    final rows = _database.select(
      '''
      SELECT
        id,
        campaign_id,
        definition_id,
        custom_name,
        quantity,
        equipped,
        holder_entity_type,
        holder_entity_id,
        container_item_id,
        notes,
        created_at,
        updated_at
      FROM item_instances
      WHERE campaign_id = ?
      ORDER BY created_at, id
      ''',
      <Object?>[campaignId.trim()],
    );
    return rows.map(_itemFromRow).toList(growable: false);
  }

  @override
  Future<void> save(ItemInstance item) async {
    final holder = item.placement.holder;
    _database.execute(
      '''
      INSERT INTO item_instances (
        id,
        campaign_id,
        definition_id,
        custom_name,
        quantity,
        equipped,
        holder_entity_type,
        holder_entity_id,
        container_item_id,
        notes,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        definition_id = excluded.definition_id,
        custom_name = excluded.custom_name,
        quantity = excluded.quantity,
        equipped = excluded.equipped,
        holder_entity_type = excluded.holder_entity_type,
        holder_entity_id = excluded.holder_entity_id,
        container_item_id = excluded.container_item_id,
        notes = excluded.notes,
        updated_at = excluded.updated_at
      ''',
      <Object?>[
        item.id,
        item.campaignId,
        item.definitionId,
        item.customName,
        item.quantity,
        item.equipped ? 1 : 0,
        holder?.entityType,
        holder?.entityId,
        item.placement.containerItemId,
        item.notes,
        item.createdAt.millisecondsSinceEpoch,
        item.updatedAt.millisecondsSinceEpoch,
      ],
    );
  }

  void close() {
    _database.close();
  }

  ItemInstance _itemFromRow(Row row) {
    final holderType = row['holder_entity_type'] as String?;
    final holderId = row['holder_entity_id'] as String?;
    final containerItemId = row['container_item_id'] as String?;

    final ItemPlacement placement;
    if (containerItemId != null) {
      placement = ItemPlacement(containerItemId: containerItemId);
    } else if (holderType != null && holderId != null) {
      placement = ItemPlacement(
        holder: InventoryHolderRef(
          entityType: holderType,
          entityId: holderId,
        ),
      );
    } else {
      placement = ItemPlacement.unassigned();
    }

    return ItemInstance(
      id: row['id'] as String,
      campaignId: row['campaign_id'] as String,
      definitionId: row['definition_id'] as String?,
      customName: row['custom_name'] as String?,
      quantity: row['quantity'] as int,
      equipped: (row['equipped'] as int) == 1,
      placement: placement,
      notes: row['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at'] as int,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at'] as int,
        isUtc: true,
      ),
    );
  }
}

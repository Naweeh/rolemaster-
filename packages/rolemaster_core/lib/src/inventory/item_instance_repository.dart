import 'item_instance.dart';

abstract interface class ItemInstanceRepository {
  Future<ItemInstance?> getById(String id);

  Future<List<ItemInstance>> getForCampaign(String campaignId);

  Future<void> save(ItemInstance item);
}
